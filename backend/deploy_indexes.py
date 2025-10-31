#!/usr/bin/env python3
"""
Deploy Firestore Indexes Script
Deploys indexes defined in firestore.indexes.json to Firebase
"""
import subprocess
import sys
import json
from pathlib import Path


def check_firebase_cli():
    """Check if Firebase CLI is installed"""
    try:
        result = subprocess.run(
            ['firebase', '--version'],
            capture_output=True,
            text=True
        )
        print(f"✓ Firebase CLI installed: {result.stdout.strip()}")
        return True
    except FileNotFoundError:
        print("✗ Firebase CLI not found!")
        print("\nInstall Firebase CLI:")
        print("  npm install -g firebase-tools")
        return False


def check_firebase_login():
    """Check if user is logged into Firebase"""
    try:
        result = subprocess.run(
            ['firebase', 'login:list'],
            capture_output=True,
            text=True
        )
        if result.returncode == 0 and result.stdout:
            print("✓ Firebase login verified")
            return True
        else:
            print("✗ Not logged into Firebase")
            print("\nLogin to Firebase:")
            print("  firebase login")
            return False
    except Exception as e:
        print(f"✗ Error checking Firebase login: {e}")
        return False


def validate_indexes_file():
    """Validate firestore.indexes.json exists and is valid JSON"""
    indexes_file = Path('firestore.indexes.json')
    
    if not indexes_file.exists():
        print(f"✗ File not found: {indexes_file}")
        return False
    
    try:
        with open(indexes_file, 'r') as f:
            data = json.load(f)
        
        if 'indexes' not in data:
            print("✗ Invalid format: 'indexes' key not found")
            return False
        
        num_indexes = len(data['indexes'])
        print(f"✓ Found {num_indexes} index(es) in firestore.indexes.json")
        
        # Display indexes
        for i, index in enumerate(data['indexes'], 1):
            fields = [f['fieldPath'] for f in index['fields']]
            print(f"  {i}. {index['collectionGroup']}: {', '.join(fields)}")
        
        return True
    
    except json.JSONDecodeError as e:
        print(f"✗ Invalid JSON: {e}")
        return False
    except Exception as e:
        print(f"✗ Error reading file: {e}")
        return False


def deploy_indexes():
    """Deploy indexes to Firestore"""
    print("\n📤 Deploying indexes to Firestore...")
    print("This may take a few minutes...\n")
    
    try:
        result = subprocess.run(
            ['firebase', 'deploy', '--only', 'firestore:indexes'],
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✓ Indexes deployed successfully!")
            print("\n📝 Note: Index building may take 1-5 minutes to complete.")
            print("   Check status at: https://console.firebase.google.com/project/mealy-41bf0/firestore/indexes")
            return True
        else:
            print("✗ Deployment failed!")
            print(f"\nError: {result.stderr}")
            return False
    
    except Exception as e:
        print(f"✗ Error deploying indexes: {e}")
        return False


def main():
    """Main deployment workflow"""
    print("=" * 60)
    print("Firestore Index Deployment Script")
    print("=" * 60)
    print()
    
    # Step 1: Check Firebase CLI
    if not check_firebase_cli():
        sys.exit(1)
    
    # Step 2: Check Firebase login
    if not check_firebase_login():
        sys.exit(1)
    
    # Step 3: Validate indexes file
    if not validate_indexes_file():
        sys.exit(1)
    
    # Step 4: Confirm deployment
    print("\n⚠️  Ready to deploy indexes to Firebase project 'mealy-41bf0'")
    response = input("Continue? (y/N): ").strip().lower()
    
    if response != 'y':
        print("Deployment cancelled.")
        sys.exit(0)
    
    # Step 5: Deploy
    if deploy_indexes():
        print("\n✓ All done!")
        print("\nNext steps:")
        print("1. Wait 1-5 minutes for indexes to build")
        print("2. Check status: firebase firestore:indexes")
        print("3. Test your queries")
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == '__main__':
    main()
