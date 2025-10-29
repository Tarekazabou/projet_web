import requests
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def test_usda_api():
    """Test USDA FoodData Central API connection"""
    
    api_key = os.getenv('USDA_API_KEY')
    
    if not api_key or api_key == 'PASTE_YOUR_ACTUAL_USDA_API_KEY_HERE':
        print("❌ Please add your USDA API key to the .env file")
        return
    
    # Test API with a simple search
    base_url = "https://api.nal.usda.gov/fdc/v1"
    
    # Test 1: Search for chicken
    search_url = f"{base_url}/foods/search"
    params = {
        'query': 'chicken breast',
        'pageSize': 5,
        'api_key': api_key
    }
    
    try:
        print("🔍 Testing USDA API search...")
        response = requests.get(search_url, params=params)
        
        if response.status_code == 200:
            data = response.json()
            foods = data.get('foods', [])
            
            print(f"✅ API connection successful!")
            print(f"📊 Found {len(foods)} food items for 'chicken breast'")
            
            if foods:
                first_food = foods[0]
                print(f"📖 Sample food: {first_food.get('description', 'N/A')}")
                print(f"🆔 FDC ID: {first_food.get('fdcId', 'N/A')}")
                
                # Test 2: Get detailed nutrition info
                fdc_id = first_food.get('fdcId')
                if fdc_id:
                    detail_url = f"{base_url}/food/{fdc_id}"
                    detail_params = {'api_key': api_key}
                    
                    detail_response = requests.get(detail_url, params=detail_params)
                    if detail_response.status_code == 200:
                        detail_data = detail_response.json()
                        nutrients = detail_data.get('foodNutrients', [])
                        print(f"🥗 Nutrition data available: {len(nutrients)} nutrients")
                        
                        # Show sample nutrients
                        for nutrient in nutrients[:3]:
                            name = nutrient.get('nutrient', {}).get('name', 'Unknown')
                            amount = nutrient.get('amount', 0)
                            unit = nutrient.get('nutrient', {}).get('unitName', '')
                            print(f"   • {name}: {amount} {unit}")
                    else:
                        print(f"⚠️ Could not get detailed nutrition data")
            
        elif response.status_code == 403:
            print("❌ API key is invalid or expired")
            print("Please check your USDA API key in the .env file")
            
        elif response.status_code == 429:
            print("⚠️ Rate limit exceeded")
            print("You've made too many requests. Try again later.")
            
        else:
            print(f"❌ API request failed with status code: {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")

if __name__ == "__main__":
    print("🧪 Testing USDA FoodData Central API...")
    print("=" * 50)
    test_usda_api()