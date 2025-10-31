"""
RAG Service for Recipe Generation
Uses the 13k-recipes.csv dataset to provide context for AI generation
"""
import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

from google import generativeai as genai
import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


class RecipeRAGService:
    """Retrieval-Augmented Generation service for recipes."""

    def __init__(
        self,
        csv_path: Optional[str] = None,
        embedding_cache_path: Optional[str] = None,
        api_key: Optional[str] = None,
        preload_embeddings: bool = False,
        max_index_size: Optional[int] = None,
    ):
        """Initialize RAG service with recipe dataset and optional embedding index."""

        project_root = Path(os.getenv("PROJECT_ROOT", Path(__file__).parent.parent))
        if csv_path is None:
            csv_path = str(project_root / "13k-recipes.csv")

        self.csv_path = Path(csv_path)
        self.recipes_df: Optional[pd.DataFrame] = None

        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        self.embedding_model = "models/text-embedding-004"
        self._gemini_configured = False

        if max_index_size is None:
            env_limit = os.getenv("RAG_MAX_EMBEDDED_RECIPES")
            max_index_size = int(env_limit) if env_limit and env_limit.isdigit() else None

        if isinstance(max_index_size, int) and max_index_size <= 0:
            max_index_size = None

        self.max_index_size = max_index_size

        if embedding_cache_path is None:
            data_dir = project_root / "backend" / "data"
        else:
            data_dir = Path(embedding_cache_path).parent

        data_dir.mkdir(parents=True, exist_ok=True)
        self.embedding_cache_path = (
            Path(embedding_cache_path)
            if embedding_cache_path
            else data_dir / "recipe_embeddings.npz"
        )
        self.embedding_meta_path = self.embedding_cache_path.with_suffix(".meta.json")

        self._recipe_embeddings: Optional[np.ndarray] = None
        self._recipe_embedding_norms: Optional[np.ndarray] = None
        self._normalized_embeddings: Optional[np.ndarray] = None
        self._recipe_index: Optional[np.ndarray] = None

        self._load_recipes()

        if preload_embeddings:
            self._ensure_embeddings_ready()

    def _load_recipes(self) -> None:
        """Load recipes from CSV file."""

        if not self.csv_path.exists():
            logger.warning("Recipe CSV not found at %s", self.csv_path)
            self.recipes_df = pd.DataFrame()
            return

        try:
            logger.info("Loading recipes from %s", self.csv_path)
            self.recipes_df = pd.read_csv(self.csv_path)
            if not self.recipes_df.empty:
                self.recipes_df.fillna("", inplace=True)
            logger.info("Loaded %d recipes", len(self.recipes_df))
        except Exception as exc:
            logger.error("Error loading recipes: %s", exc)
            self.recipes_df = pd.DataFrame()

    def _configure_gemini(self) -> None:
        """Configure the Gemini SDK if an API key is available."""

        if self._gemini_configured:
            return

        if not self.api_key:
            raise ValueError("GEMINI_API_KEY not found. Semantic retrieval requires this key.")

        genai.configure(api_key=self.api_key)
        self._gemini_configured = True

    def _load_embedding_cache(self) -> bool:
        """Load cached embeddings from disk if present."""

        if not self.embedding_cache_path.exists():
            return False

        try:
            data = np.load(self.embedding_cache_path)
            self._recipe_embeddings = data["embeddings"].astype(np.float32)
            norms = data["norms"].astype(np.float32)
            norms[norms == 0] = 1e-12
            self._recipe_embedding_norms = norms
            self._normalized_embeddings = self._recipe_embeddings / norms[:, None]
            self._recipe_index = data["recipe_ids"].astype(np.int32)
            logger.info(
                "Loaded recipe embedding index for %d recipes from %s",
                self._recipe_embeddings.shape[0],
                self.embedding_cache_path,
            )
            return True
        except Exception as exc:
            logger.error("Failed to load embedding cache: %s", exc)
            self._recipe_embeddings = None
            self._recipe_embedding_norms = None
            self._normalized_embeddings = None
            self._recipe_index = None
            return False

    def _save_embedding_cache(self) -> None:
        """Persist the embedding index to disk for reuse."""

        if (
            self._recipe_embeddings is None
            or self._recipe_embedding_norms is None
            or self._recipe_index is None
        ):
            return

        try:
            np.savez_compressed(
                self.embedding_cache_path,
                embeddings=self._recipe_embeddings.astype(np.float32),
                norms=self._recipe_embedding_norms.astype(np.float32),
                recipe_ids=self._recipe_index.astype(np.int32),
            )

            meta = {
                "recipe_count": int(self._recipe_embeddings.shape[0]),
                "embedding_dim": int(self._recipe_embeddings.shape[1]),
                "model": self.embedding_model,
                "csv_path": str(self.csv_path),
                "generated_at": datetime.utcnow().isoformat() + "Z",
            }

            with open(self.embedding_meta_path, "w", encoding="utf-8") as meta_file:
                json.dump(meta, meta_file, indent=2)

            logger.info("Saved embedding cache to %s", self.embedding_cache_path)
        except Exception as exc:
            logger.error("Failed to persist embedding cache: %s", exc)

    def _format_recipe_for_embedding(self, row: pd.Series) -> str:
        """Create a text representation of a recipe for embedding."""

        title = str(row.get("Title", "")).strip()
        ingredients = str(row.get("Ingredients", "")).strip()
        instructions = str(row.get("Instructions", "")).strip()

        return (
            f"Title: {title}\n"
            f"Ingredients: {ingredients}\n"
            f"Instructions: {instructions}"
        )

    def _ensure_embeddings_ready(self) -> bool:
        """Make sure semantic embeddings are available before retrieval."""

        if (
            self._recipe_embeddings is not None
            and self._normalized_embeddings is not None
            and self._recipe_index is not None
        ):
            return True

        if self._load_embedding_cache():
            return True

        if not self.api_key:
            logger.warning(
                "Semantic retrieval disabled: GEMINI_API_KEY not provided."
            )
            return False

        if self.recipes_df is None or self.recipes_df.empty:
            logger.warning("Recipe dataset is empty; cannot build embeddings.")
            return False

        self._build_embeddings_index()
        return (
            self._recipe_embeddings is not None
            and self._normalized_embeddings is not None
            and self._recipe_index is not None
        )

    def _build_embeddings_index(self) -> None:
        """Generate embeddings for the recipe dataset using Gemini."""

        try:
            self._configure_gemini()
        except ValueError as exc:
            logger.error("Cannot build embeddings: %s", exc)
            return

        if self.recipes_df is None or self.recipes_df.empty:
            logger.warning("No recipes loaded; skipping embedding generation.")
            return

        iterable = (
            self.recipes_df.head(self.max_index_size)
            if self.max_index_size
            else self.recipes_df
        )

        embeddings: List[np.ndarray] = []
        recipe_ids: List[int] = []

        total = len(iterable)
        logger.info(
            "Building recipe embedding index for %d recipes using %s",
            total,
            self.embedding_model,
        )

        for counter, (row_index, row) in enumerate(iterable.iterrows(), start=1):
            recipe_text = self._format_recipe_for_embedding(row)

            try:
                embedding_response = genai.embed_content(
                    model=self.embedding_model,
                    content=recipe_text,
                )

                vector = embedding_response.get("embedding")
                if not vector:
                    logger.debug(
                        "No embedding returned for recipe index %s", row_index
                    )
                    continue

                embeddings.append(np.asarray(vector, dtype=np.float32))
                recipe_ids.append(int(row_index))
            except Exception as exc:
                logger.error(
                    "Failed to embed recipe at index %s: %s", row_index, exc
                )
                continue

            if counter % 250 == 0:
                logger.info("Embedded %d/%d recipes", counter, total)

        if not embeddings:
            logger.error(
                "Embedding generation produced no vectors; semantic retrieval unavailable."
            )
            return

        self._recipe_embeddings = np.vstack(embeddings)
        norms = np.linalg.norm(self._recipe_embeddings, axis=1)
        norms[norms == 0] = 1e-12
        self._recipe_embedding_norms = norms
        self._normalized_embeddings = self._recipe_embeddings / norms[:, None]
        self._recipe_index = np.asarray(recipe_ids, dtype=np.int32)

        self._save_embedding_cache()

    def _compose_search_text(
        self,
        user_query: Optional[str],
        user_requirements: Optional[Dict[str, Any]],
    ) -> str:
        """Combine the user query and constraints into a single semantic string."""

        segments: List[str] = []

        if user_query:
            segments.append(user_query.strip())

        requirements = user_requirements or {}

        ingredients = requirements.get("ingredients") or []
        if ingredients:
            segments.append("Ingredients: " + ", ".join(ingredients))

        dietary = requirements.get("dietary_preferences") or []
        if dietary:
            segments.append("Dietary preferences: " + ", ".join(dietary))

        cooking_time = requirements.get("max_cooking_time")
        if cooking_time:
            segments.append(f"Max cooking time: {cooking_time} minutes")

        difficulty = requirements.get("difficulty")
        if difficulty:
            segments.append(f"Difficulty: {difficulty}")

        servings = requirements.get("servings")
        if servings:
            segments.append(f"Servings: {servings}")

        return "\n".join(filter(None, segments)).strip()

    def _extract_keywords(
        self,
        user_query: Optional[str],
        user_requirements: Optional[Dict[str, Any]],
    ) -> List[str]:
        """Create a keyword list for lexical fallback searches."""

        keywords: List[str] = []

        if user_query:
            for token in user_query.replace(",", " ").split():
                token = token.lower().strip()
                if len(token) > 2 and token not in keywords:
                    keywords.append(token)

        requirements = user_requirements or {}
        for field in ["ingredients", "dietary_preferences"]:
            for value in requirements.get(field, []) or []:
                token = str(value).lower().strip()
                if token and token not in keywords:
                    keywords.append(token)

        if requirements.get("difficulty"):
            token = str(requirements["difficulty"]).lower().strip()
            if token and token not in keywords:
                keywords.append(token)

        return keywords[:20]

    def _embed_query(self, text: str) -> Optional[np.ndarray]:
        """Generate a normalized embedding for the query text."""

        if not text:
            return None

        if not self._ensure_embeddings_ready():
            return None

        try:
            self._configure_gemini()
            response = genai.embed_content(
                model=self.embedding_model,
                content=text,
            )

            vector = response.get("embedding")
            if not vector:
                return None

            embedding = np.asarray(vector, dtype=np.float32)
            norm = np.linalg.norm(embedding)
            if norm == 0:
                return None

            return embedding / norm
        except Exception as exc:
            logger.error("Failed to embed query text: %s", exc)
            return None

    def retrieve_relevant_recipes(
        self,
        user_query: Optional[str],
        user_requirements: Optional[Dict[str, Any]],
        top_k: int = 5,
    ) -> List[Dict[str, Any]]:
        """Retrieve the top-K semantically similar recipes for the given query."""

        if self.recipes_df is None or self.recipes_df.empty:
            return []

        search_text = self._compose_search_text(user_query, user_requirements)
        if not search_text:
            return []

        query_vector = self._embed_query(search_text)
        if query_vector is None or self._normalized_embeddings is None:
            logger.debug(
                "Semantic retrieval unavailable; falling back to keyword search."
            )
            keywords = self._extract_keywords(user_query, user_requirements)
            return self.retrieve_by_keywords(keywords, limit=top_k)

        similarities = self._normalized_embeddings @ query_vector

        if similarities.size == 0:
            return []

        top_indices = np.argsort(similarities)[::-1][:top_k]

        results: List[Dict[str, Any]] = []
        for rank, idx in enumerate(top_indices, start=1):
            recipe_id = int(self._recipe_index[idx]) if self._recipe_index is not None else int(idx)
            try:
                recipe_row = self.recipes_df.loc[recipe_id]
            except Exception:
                continue

            results.append(
                {
                    "title": recipe_row.get("Title", ""),
                    "ingredients": recipe_row.get("Ingredients", ""),
                    "instructions": recipe_row.get("Instructions", ""),
                    "similarity": round(float(similarities[idx]), 6),
                    "dataset_index": recipe_id,
                    "rank": rank,
                }
            )

        logger.info("Retrieved %d semantic matches for query", len(results))
        return results

    def retrieve_similar_recipes(
        self,
        ingredients: List[str],
        limit: int = 5,
    ) -> List[Dict[str, Any]]:
        """Lexical ingredient matching (legacy fallback)."""

        if self.recipes_df is None or self.recipes_df.empty:
            return []

        try:
            search_terms = [ing.lower() for ing in ingredients]

            def score_recipe(recipe_ingredients: Any) -> int:
                if isinstance(recipe_ingredients, float) and np.isnan(recipe_ingredients):
                    return 0

                recipe_text = str(recipe_ingredients).lower()
                return sum(1 for term in search_terms if term in recipe_text)

            self.recipes_df["match_score"] = self.recipes_df["Ingredients"].apply(score_recipe)
            matching_recipes = self.recipes_df[self.recipes_df["match_score"] > 0]
            top_recipes = matching_recipes.nlargest(limit, "match_score")

            results = []
            for _, recipe in top_recipes.iterrows():
                results.append(
                    {
                        "title": recipe.get("Title", ""),
                        "ingredients": recipe.get("Ingredients", ""),
                        "instructions": recipe.get("Instructions", ""),
                        "match_score": recipe.get("match_score", 0),
                    }
                )

            logger.info("Retrieved %d keyword matches", len(results))
            return results

        except Exception as exc:
            logger.error("Error retrieving recipes: %s", exc)
            return []

    def retrieve_by_keywords(
        self,
        keywords: List[str],
        limit: int = 3,
    ) -> List[Dict[str, Any]]:
        """Retrieve recipes based on keywords (broader search)."""

        if self.recipes_df is None or self.recipes_df.empty:
            return []

        try:
            search_terms = [kw.lower() for kw in keywords]

            def score_recipe(row: pd.Series) -> int:
                text = (
                    f"{row.get('Title', '')} "
                    f"{row.get('Ingredients', '')} "
                    f"{row.get('Instructions', '')}"
                ).lower()
                return sum(1 for term in search_terms if term and term in text)

            self.recipes_df["keyword_score"] = self.recipes_df.apply(score_recipe, axis=1)
            matching = self.recipes_df[self.recipes_df["keyword_score"] > 0]
            top_recipes = matching.nlargest(limit, "keyword_score")

            results = []
            for _, recipe in top_recipes.iterrows():
                results.append(
                    {
                        "title": recipe.get("Title", ""),
                        "ingredients": recipe.get("Ingredients", ""),
                        "instructions": recipe.get("Instructions", ""),
                        "keyword_score": recipe.get("keyword_score", 0),
                    }
                )

            return results

        except Exception as exc:
            logger.error("Error in keyword search: %s", exc)
            return []

    def build_context_prompt(
        self,
        user_query: Optional[str],
        similar_recipes: List[Dict[str, Any]],
        user_requirements: Dict[str, Any],
    ) -> str:
        """Build an enhanced prompt with retrieved recipes as context."""

        prompt_parts: List[str] = []

        prompt_parts.append(
            "You are an inventive yet reliable culinary AI assistant."
        )

        if user_query:
            prompt_parts.append("\nUser query:")
            prompt_parts.append(user_query.strip())
        else:
            prompt_parts.append(
                "\nUser query: Create a recipe that satisfies the provided requirements."
            )

        prompt_parts.append(
            "\nRetrieved reference recipes (most relevant first). Use them as inspiration only:"
        )

        if similar_recipes:
            for recipe in similar_recipes[:5]:
                prompt_parts.append(
                    f"\n- {recipe.get('title', 'Unknown recipe')}"
                )
                if "similarity" in recipe:
                    prompt_parts.append(
                        f"  Similarity: {recipe.get('similarity')}"
                    )
                elif "match_score" in recipe:
                    prompt_parts.append(
                        f"  Match score: {recipe.get('match_score')}"
                    )

                ingredients = str(recipe.get("ingredients", ""))
                prompt_parts.append(
                    "  Key ingredients: " + ingredients[:300]
                )

                instructions = str(recipe.get("instructions", ""))
                prompt_parts.append(
                    "  Instructions excerpt: " + instructions[:400]
                )
        else:
            prompt_parts.append(
                "\n(No relevant recipes were retrieved. Lean on general culinary knowledge.)"
            )

        prompt_parts.append("\nUser requirements and constraints:")
        if user_requirements:
            if user_requirements.get("ingredients"):
                prompt_parts.append(
                    "- Required ingredients: "
                    + ", ".join(user_requirements.get("ingredients", []))
                )
            if user_requirements.get("dietary_preferences"):
                prompt_parts.append(
                    "- Dietary preferences: "
                    + ", ".join(user_requirements.get("dietary_preferences", []))
                )
            if user_requirements.get("max_cooking_time"):
                prompt_parts.append(
                    f"- Maximum cooking time: {user_requirements['max_cooking_time']} minutes"
                )
            if user_requirements.get("difficulty"):
                prompt_parts.append(
                    f"- Target difficulty: {user_requirements['difficulty']}"
                )
            if user_requirements.get("servings"):
                prompt_parts.append(
                    f"- Servings: {user_requirements['servings']}"
                )
        else:
            prompt_parts.append("- No additional constraints provided.")

        prompt_parts.append("\nWhen crafting the final recipe:")
        prompt_parts.append("- Produce an original creation inspired by the references without copying them.")
        prompt_parts.append("- Highlight the required ingredients and respect dietary needs.")
        prompt_parts.append("- Ensure instructions are sequential, clear, and practical.")
        prompt_parts.append(
            "- Estimate nutrition facts (calories, protein, carbs, fat, fiber) per serving."
        )
        prompt_parts.append("- Keep the tone helpful and encouraging.")

        return "\n".join(prompt_parts)

    def get_random_recipes(self, limit: int = 5) -> List[Dict[str, Any]]:
        """Get random recipes for inspiration when no specific requirements."""

        if self.recipes_df is None or self.recipes_df.empty:
            return []

        try:
            sample_size = min(limit, len(self.recipes_df))
            random_recipes = self.recipes_df.sample(n=sample_size)

            results = []
            for _, recipe in random_recipes.iterrows():
                results.append(
                    {
                        "title": recipe.get("Title", ""),
                        "ingredients": recipe.get("Ingredients", ""),
                        "instructions": recipe.get("Instructions", ""),
                    }
                )

            return results
        except Exception as exc:
            logger.error("Error getting random recipes: %s", exc)
            return []
