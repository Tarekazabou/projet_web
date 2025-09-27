from flask import Blueprint, request, jsonify, current_app
from bson import ObjectId
import logging
from datetime import datetime
from backend.models.models import Feedback

logger = logging.getLogger(__name__)
feedback_bp = Blueprint('feedback', __name__)

@feedback_bp.route('/', methods=['POST'])
def submit_feedback():
    """Submit feedback for a recipe"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        required_fields = ['user_id', 'recipe_id', 'rating']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Validate IDs
        user_id = data['user_id']
        recipe_id = data['recipe_id']
        
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        # Validate rating
        rating = data['rating']
        if not isinstance(rating, (int, float)) or rating < 1 or rating > 5:
            return jsonify({'error': 'Rating must be between 1 and 5'}), 400
        
        # Check if user already provided feedback for this recipe
        db = current_app.mongo.db
        existing_feedback = db.feedback.find_one({
            'user_id': user_id,
            'recipe_id': recipe_id
        })
        
        if existing_feedback:
            # Update existing feedback
            update_data = {
                'rating': rating,
                'comment': data.get('comment', ''),
                'difficulty_rating': data.get('difficulty_rating'),
                'would_make_again': data.get('would_make_again'),
                'created_at': datetime.utcnow()
            }
            
            db.feedback.update_one(
                {'_id': existing_feedback['_id']},
                {'$set': update_data}
            )
            
            feedback_id = existing_feedback['_id']
            message = 'Feedback updated successfully'
        else:
            # Create new feedback
            feedback = Feedback(
                user_id=user_id,
                recipe_id=recipe_id,
                rating=rating,
                comment=data.get('comment', ''),
                difficulty_rating=data.get('difficulty_rating'),
                would_make_again=data.get('would_make_again')
            )
            
            result = db.feedback.insert_one(feedback.to_dict())
            feedback_id = result.inserted_id
            message = 'Feedback submitted successfully'
        
        # Update recipe rating statistics
        update_recipe_rating(db, recipe_id)
        
        # Return created/updated feedback
        updated_feedback = db.feedback.find_one({'_id': feedback_id})
        updated_feedback['_id'] = str(updated_feedback['_id'])
        
        return jsonify({
            'message': message,
            'feedback': updated_feedback
        }), 201 if not existing_feedback else 200
        
    except Exception as e:
        logger.error(f"Error submitting feedback: {e}")
        return jsonify({'error': 'Failed to submit feedback'}), 500

@feedback_bp.route('/recipe/<recipe_id>', methods=['GET'])
def get_recipe_feedback(recipe_id):
    """Get all feedback for a specific recipe"""
    try:
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 20, type=int))
        sort_by = request.args.get('sort_by', 'created_at')  # created_at, rating, helpful_votes
        
        db = current_app.mongo.db
        
        # Build sort criteria
        sort_criteria = []
        if sort_by == 'rating':
            sort_criteria = [('rating', -1), ('created_at', -1)]
        elif sort_by == 'helpful_votes':
            sort_criteria = [('helpful_votes', -1), ('created_at', -1)]
        else:
            sort_criteria = [('created_at', -1)]
        
        # Get feedback with pagination
        total_count = db.feedback.count_documents({'recipe_id': recipe_id})
        
        feedback_list = list(db.feedback.find({'recipe_id': recipe_id})
                           .sort(sort_criteria)
                           .skip((page - 1) * per_page)
                           .limit(per_page))
        
        # Get user information for each feedback
        user_ids = [ObjectId(fb['user_id']) for fb in feedback_list]
        users = {str(user['_id']): user for user in db.users.find({'_id': {'$in': user_ids}})}
        
        # Add user info to feedback
        for feedback in feedback_list:
            feedback['_id'] = str(feedback['_id'])
            user_info = users.get(feedback['user_id'])
            if user_info:
                feedback['username'] = user_info.get('username', 'Anonymous')
            else:
                feedback['username'] = 'Anonymous'
        
        # Calculate feedback statistics
        stats = calculate_feedback_stats(db, recipe_id)
        
        return jsonify({
            'feedback': feedback_list,
            'statistics': stats,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_count': total_count,
                'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting recipe feedback: {e}")
        return jsonify({'error': 'Failed to get feedback'}), 500

@feedback_bp.route('/user/<user_id>', methods=['GET'])
def get_user_feedback(user_id):
    """Get all feedback submitted by a user"""
    try:
        if not ObjectId.is_valid(user_id):
            return jsonify({'error': 'Invalid user ID'}), 400
        
        page = max(1, request.args.get('page', 1, type=int))
        per_page = min(50, request.args.get('per_page', 20, type=int))
        
        db = current_app.mongo.db
        total_count = db.feedback.count_documents({'user_id': user_id})
        
        feedback_list = list(db.feedback.find({'user_id': user_id})
                           .sort('created_at', -1)
                           .skip((page - 1) * per_page)
                           .limit(per_page))
        
        # Get recipe information for each feedback
        recipe_ids = [ObjectId(fb['recipe_id']) for fb in feedback_list]
        recipes = {str(recipe['_id']): recipe for recipe in db.recipes.find({'_id': {'$in': recipe_ids}})}
        
        # Add recipe info to feedback
        for feedback in feedback_list:
            feedback['_id'] = str(feedback['_id'])
            recipe_info = recipes.get(feedback['recipe_id'])
            if recipe_info:
                feedback['recipe_title'] = recipe_info.get('title', 'Unknown Recipe')
            else:
                feedback['recipe_title'] = 'Unknown Recipe'
        
        return jsonify({
            'feedback': feedback_list,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total_count': total_count,
                'total_pages': (total_count + per_page - 1) // per_page
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting user feedback: {e}")
        return jsonify({'error': 'Failed to get user feedback'}), 500

@feedback_bp.route('/<feedback_id>/helpful', methods=['POST'])
def mark_helpful(feedback_id):
    """Mark feedback as helpful"""
    try:
        if not ObjectId.is_valid(feedback_id):
            return jsonify({'error': 'Invalid feedback ID'}), 400
        
        data = request.get_json()
        user_id = data.get('user_id') if data else None
        
        db = current_app.mongo.db
        
        # Check if user already marked this feedback as helpful
        if user_id:
            existing_vote = db.helpful_votes.find_one({
                'feedback_id': feedback_id,
                'user_id': user_id
            })
            
            if existing_vote:
                return jsonify({'error': 'You have already marked this feedback as helpful'}), 400
            
            # Record the helpful vote
            db.helpful_votes.insert_one({
                'feedback_id': feedback_id,
                'user_id': user_id,
                'created_at': datetime.utcnow()
            })
        
        # Increment helpful votes count
        result = db.feedback.update_one(
            {'_id': ObjectId(feedback_id)},
            {'$inc': {'helpful_votes': 1}}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Feedback not found'}), 404
        
        # Get updated feedback
        updated_feedback = db.feedback.find_one({'_id': ObjectId(feedback_id)})
        
        return jsonify({
            'message': 'Marked as helpful',
            'helpful_votes': updated_feedback.get('helpful_votes', 0)
        }), 200
        
    except Exception as e:
        logger.error(f"Error marking feedback as helpful: {e}")
        return jsonify({'error': 'Failed to mark as helpful'}), 500

@feedback_bp.route('/<feedback_id>', methods=['DELETE'])
def delete_feedback(feedback_id):
    """Delete feedback (only by feedback author)"""
    try:
        if not ObjectId.is_valid(feedback_id):
            return jsonify({'error': 'Invalid feedback ID'}), 400
        
        data = request.get_json()
        user_id = data.get('user_id') if data else None
        
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400
        
        db = current_app.mongo.db
        
        # Check if feedback exists and belongs to user
        feedback = db.feedback.find_one({'_id': ObjectId(feedback_id)})
        
        if not feedback:
            return jsonify({'error': 'Feedback not found'}), 404
        
        if feedback['user_id'] != user_id:
            return jsonify({'error': 'Not authorized to delete this feedback'}), 403
        
        # Delete feedback
        recipe_id = feedback['recipe_id']
        db.feedback.delete_one({'_id': ObjectId(feedback_id)})
        
        # Delete associated helpful votes
        db.helpful_votes.delete_many({'feedback_id': feedback_id})
        
        # Update recipe rating statistics
        update_recipe_rating(db, recipe_id)
        
        return jsonify({'message': 'Feedback deleted successfully'}), 200
        
    except Exception as e:
        logger.error(f"Error deleting feedback: {e}")
        return jsonify({'error': 'Failed to delete feedback'}), 500

@feedback_bp.route('/analytics/recipe/<recipe_id>', methods=['GET'])
def get_feedback_analytics(recipe_id):
    """Get detailed feedback analytics for a recipe"""
    try:
        if not ObjectId.is_valid(recipe_id):
            return jsonify({'error': 'Invalid recipe ID'}), 400
        
        db = current_app.mongo.db
        
        # Get comprehensive analytics
        analytics = {
            'rating_distribution': get_rating_distribution(db, recipe_id),
            'difficulty_feedback': get_difficulty_feedback(db, recipe_id),
            'would_make_again_ratio': get_would_make_again_ratio(db, recipe_id),
            'comment_themes': analyze_comment_themes(db, recipe_id),
            'feedback_trends': get_feedback_trends(db, recipe_id)
        }
        
        return jsonify({
            'analytics': analytics,
            'recipe_id': recipe_id
        }), 200
        
    except Exception as e:
        logger.error(f"Error getting feedback analytics: {e}")
        return jsonify({'error': 'Failed to get analytics'}), 500

def update_recipe_rating(db, recipe_id):
    """Update recipe's average rating and review count"""
    try:
        # Calculate new rating statistics
        pipeline = [
            {'$match': {'recipe_id': recipe_id}},
            {'$group': {
                '_id': None,
                'avg_rating': {'$avg': '$rating'},
                'count': {'$sum': 1}
            }}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        
        if result:
            avg_rating = round(result[0]['avg_rating'], 1)
            count = result[0]['count']
        else:
            avg_rating = 0.0
            count = 0
        
        # Update recipe
        db.recipes.update_one(
            {'_id': ObjectId(recipe_id)},
            {'$set': {
                'rating': avg_rating,
                'review_count': count,
                'updated_at': datetime.utcnow()
            }}
        )
        
    except Exception as e:
        logger.error(f"Error updating recipe rating: {e}")

def calculate_feedback_stats(db, recipe_id):
    """Calculate feedback statistics for a recipe"""
    try:
        pipeline = [
            {'$match': {'recipe_id': recipe_id}},
            {'$group': {
                '_id': None,
                'avg_rating': {'$avg': '$rating'},
                'count': {'$sum': 1},
                'five_stars': {'$sum': {'$cond': [{'$eq': ['$rating', 5]}, 1, 0]}},
                'four_stars': {'$sum': {'$cond': [{'$eq': ['$rating', 4]}, 1, 0]}},
                'three_stars': {'$sum': {'$cond': [{'$eq': ['$rating', 3]}, 1, 0]}},
                'two_stars': {'$sum': {'$cond': [{'$eq': ['$rating', 2]}, 1, 0]}},
                'one_star': {'$sum': {'$cond': [{'$eq': ['$rating', 1]}, 1, 0]}},
                'avg_difficulty': {'$avg': '$difficulty_rating'},
                'would_make_again_yes': {'$sum': {'$cond': [{'$eq': ['$would_make_again', True]}, 1, 0]}},
                'would_make_again_no': {'$sum': {'$cond': [{'$eq': ['$would_make_again', False]}, 1, 0]}}
            }}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        
        if result:
            stats = result[0]
            stats.pop('_id', None)
            if stats['avg_rating']:
                stats['avg_rating'] = round(stats['avg_rating'], 1)
            if stats['avg_difficulty']:
                stats['avg_difficulty'] = round(stats['avg_difficulty'], 1)
        else:
            stats = {
                'avg_rating': 0,
                'count': 0,
                'five_stars': 0,
                'four_stars': 0,
                'three_stars': 0,
                'two_stars': 0,
                'one_star': 0,
                'avg_difficulty': 0,
                'would_make_again_yes': 0,
                'would_make_again_no': 0
            }
        
        return stats
        
    except Exception as e:
        logger.error(f"Error calculating feedback stats: {e}")
        return {}

def get_rating_distribution(db, recipe_id):
    """Get rating distribution for analytics"""
    try:
        pipeline = [
            {'$match': {'recipe_id': recipe_id}},
            {'$group': {
                '_id': '$rating',
                'count': {'$sum': 1}
            }},
            {'$sort': {'_id': -1}}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        distribution = {str(i): 0 for i in range(1, 6)}
        
        for item in result:
            distribution[str(int(item['_id']))] = item['count']
        
        return distribution
        
    except Exception as e:
        logger.error(f"Error getting rating distribution: {e}")
        return {}

def get_difficulty_feedback(db, recipe_id):
    """Get difficulty rating feedback"""
    try:
        pipeline = [
            {'$match': {'recipe_id': recipe_id, 'difficulty_rating': {'$exists': True}}},
            {'$group': {
                '_id': '$difficulty_rating',
                'count': {'$sum': 1}
            }},
            {'$sort': {'_id': 1}}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        return {str(int(item['_id'])): item['count'] for item in result}
        
    except Exception as e:
        logger.error(f"Error getting difficulty feedback: {e}")
        return {}

def get_would_make_again_ratio(db, recipe_id):
    """Get would make again ratio"""
    try:
        pipeline = [
            {'$match': {'recipe_id': recipe_id, 'would_make_again': {'$exists': True}}},
            {'$group': {
                '_id': '$would_make_again',
                'count': {'$sum': 1}
            }}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        ratio = {True: 0, False: 0}
        
        for item in result:
            ratio[item['_id']] = item['count']
        
        total = sum(ratio.values())
        if total > 0:
            ratio['percentage_yes'] = round((ratio[True] / total) * 100, 1)
        else:
            ratio['percentage_yes'] = 0
        
        return ratio
        
    except Exception as e:
        logger.error(f"Error getting would make again ratio: {e}")
        return {}

def analyze_comment_themes(db, recipe_id):
    """Analyze common themes in comments"""
    try:
        # Simple keyword analysis - in production, you might use NLP
        feedback_list = list(db.feedback.find({
            'recipe_id': recipe_id,
            'comment': {'$exists': True, '$ne': ''}
        }))
        
        positive_keywords = ['delicious', 'amazing', 'great', 'love', 'perfect', 'easy', 'tasty']
        negative_keywords = ['bland', 'difficult', 'too salty', 'dry', 'hard', 'complicated']
        
        themes = {
            'positive_mentions': 0,
            'negative_mentions': 0,
            'common_words': {}
        }
        
        for feedback in feedback_list:
            comment = feedback['comment'].lower()
            
            for keyword in positive_keywords:
                if keyword in comment:
                    themes['positive_mentions'] += 1
                    break
            
            for keyword in negative_keywords:
                if keyword in comment:
                    themes['negative_mentions'] += 1
                    break
        
        return themes
        
    except Exception as e:
        logger.error(f"Error analyzing comment themes: {e}")
        return {}

def get_feedback_trends(db, recipe_id):
    """Get feedback trends over time"""
    try:
        pipeline = [
            {'$match': {'recipe_id': recipe_id}},
            {'$group': {
                '_id': {
                    'year': {'$year': '$created_at'},
                    'month': {'$month': '$created_at'}
                },
                'avg_rating': {'$avg': '$rating'},
                'count': {'$sum': 1}
            }},
            {'$sort': {'_id.year': 1, '_id.month': 1}}
        ]
        
        result = list(db.feedback.aggregate(pipeline))
        
        trends = []
        for item in result:
            trends.append({
                'period': f"{item['_id']['year']}-{item['_id']['month']:02d}",
                'avg_rating': round(item['avg_rating'], 1),
                'count': item['count']
            })
        
        return trends
        
    except Exception as e:
        logger.error(f"Error getting feedback trends: {e}")
        return []