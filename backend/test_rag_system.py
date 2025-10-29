"""
Quick test script for RAG + AI system
Run this to verify everything is working
"""
import sys
from pathlib import Path

# Add backend to path
backend_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(backend_dir))

from services.rag_service import RecipeRAGService

def test_rag_service():
    """Test RAG service"""
    print("="*60)
    print("Testing RAG Service")
    print("="*60)
    
    try:
        # Initialize service
        print("\n1. Loading recipe dataset...")
        rag = RecipeRAGService()
        
        if rag.recipes_df is None or rag.recipes_df.empty:
            print("❌ Failed to load recipes. Check 13k-recipes.csv location.")
            return False
        
        print(f"✅ Loaded {len(rag.recipes_df)} recipes")
        
        # Test retrieval
        print("\n2. Testing ingredient search...")
        ingredients = ['chicken', 'garlic', 'tomatoes']
        results = rag.retrieve_similar_recipes(ingredients, limit=3)
        
        if results:
            print(f"✅ Found {len(results)} matching recipes:")
            for i, recipe in enumerate(results, 1):
                print(f"   {i}. {recipe['title']} (score: {recipe['match_score']})")
        else:
            print("❌ No recipes found")
            return False
        
        # Test context building
        print("\n3. Testing context prompt building...")
        user_req = {
            'ingredients': ingredients,
            'dietary_preferences': ['healthy'],
            'max_cooking_time': 30,
            'difficulty': 'easy'
        }
        
        context = rag.build_context_prompt(results, user_req)
        print(f"✅ Built context prompt ({len(context)} characters)")
        print(f"\nFirst 200 chars:\n{context[:200]}...")
        
        print("\n" + "="*60)
        print("✅ RAG Service Test: PASSED")
        print("="*60)
        return True
        
    except Exception as e:
        print(f"\n❌ RAG Service Test: FAILED")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_ai_service():
    """Test AI service (requires API key)"""
    print("\n" + "="*60)
    print("Testing AI Service")
    print("="*60)
    
    try:
        import os
        from dotenv import load_dotenv
        from services.ai_service import AIRecipeGenerator
        
        # Load environment
        load_dotenv()
        
        api_key = os.getenv('GEMINI_API_KEY')
        if not api_key or api_key == 'your_gemini_api_key_here':
            print("⚠️  GEMINI_API_KEY not configured in .env")
            print("   Get your key from: https://makersuite.google.com/app/apikey")
            print("   Add it to backend/.env file")
            print("\n   Skipping AI test...")
            return None
        
        print("\n1. Initializing AI generator...")
        ai = AIRecipeGenerator()
        print("✅ AI generator initialized")
        
        print("\n2. Generating test recipe...")
        print("   (This may take 3-5 seconds...)")
        
        recipe = ai.generate_simple_recipe(
            ingredients=['eggs', 'cheese'],
            dietary_prefs=['quick'],
            cooking_time=10
        )
        
        if recipe and 'title' in recipe:
            print(f"✅ Generated recipe: {recipe['title']}")
            print(f"   Cook time: {recipe.get('cookTimeMinutes', 'N/A')} minutes")
            print(f"   Difficulty: {recipe.get('difficulty', 'N/A')}")
        else:
            print("❌ Failed to generate recipe")
            return False
        
        print("\n" + "="*60)
        print("✅ AI Service Test: PASSED")
        print("="*60)
        return True
        
    except Exception as e:
        print(f"\n❌ AI Service Test: FAILED")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    print("\n🧪 RAG + AI System Test\n")
    
    # Test RAG
    rag_passed = test_rag_service()
    
    # Test AI (optional if API key configured)
    ai_passed = test_ai_service()
    
    # Summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    print(f"RAG Service: {'✅ PASSED' if rag_passed else '❌ FAILED'}")
    
    if ai_passed is None:
        print("AI Service:  ⚠️  SKIPPED (no API key)")
    else:
        print(f"AI Service:  {'✅ PASSED' if ai_passed else '❌ FAILED'}")
    
    print("="*60)
    
    if rag_passed and (ai_passed or ai_passed is None):
        print("\n🎉 System is ready! Start the server and test the API endpoints.")
    else:
        print("\n⚠️  Please fix the issues above before proceeding.")
