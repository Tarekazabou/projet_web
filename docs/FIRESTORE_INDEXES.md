# Firestore Index Management

This directory contains Firestore index configuration and management scripts.

## Quick Fix for Index Errors

When you see an error like:
```
The query requires an index. You can create it here: https://console.firebase.google.com/...
```

### Option 1: Use the Firebase Console (Easiest)
1. Click the link in the error message
2. Click "Create Index" in the Firebase Console
3. Wait 1-5 minutes for the index to build

### Option 2: Deploy All Indexes
```bash
# From project root
firebase deploy --only firestore:indexes
```

### Option 3: Manual Creation
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (`mealy-41bf0`)
3. Navigate to Firestore → Indexes
4. Click "Create Index"
5. Configure the fields as specified in `firestore.indexes.json`

## Current Indexes

We have defined the following composite indexes in `firestore.indexes.json`:

### 1. Dietary + Difficulty + Title
For searches with dietary preferences, difficulty, and title sorting:
- `dietaryPreferences` (array-contains)
- `difficulty` (ascending)
- `title` (ascending)

### 2. Dietary + Difficulty + Document ID
For searches with dietary preferences and difficulty:
- `dietaryPreferences` (array-contains)
- `difficulty` (ascending)
- `__name__` (ascending)

### 3. Difficulty + Rating
For sorting by rating with difficulty filter:
- `difficulty` (ascending)
- `rating` (descending)

### 4. Cuisine + Difficulty + Rating
For searches with cuisine and difficulty, sorted by rating:
- `cuisine` (ascending)
- `difficulty` (ascending)
- `rating` (descending)

### 5. Cooking Time + Rating
For searches with max cooking time, sorted by rating:
- `cookTimeMinutes` (ascending)
- `rating` (descending)

### 6. Dietary + Rating
For searches with dietary preferences, sorted by rating:
- `dietaryPreferences` (array-contains)
- `rating` (descending)

## Deploying Indexes

### Prerequisites
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not done)
firebase init firestore
```

### Deploy
```bash
# From project root
firebase deploy --only firestore:indexes
```

### Monitor Index Status
```bash
# Check index build status
firebase firestore:indexes
```

## Firestore Query Limitations

### Important Rules
1. **Only ONE inequality filter per query**
   - `<`, `<=`, `>`, `>=`, `!=`, `not-in`
   - Example: You can filter `cookTimeMinutes <= 30` OR `rating > 4`, but NOT both

2. **Order by inequality field first**
   - If you use `cookTimeMinutes <=`, you must order by `cookTimeMinutes` first
   - Then you can add secondary sorting

3. **Composite indexes required**
   - Multiple equality filters + ordering = composite index
   - Array-contains + other filters = composite index

4. **Array-contains limitations**
   - Can use `array-contains` or `array-contains-any`
   - Cannot combine `array-contains-any` with other array operations

## Recipe Search Strategy

Given Firestore limitations, our recipe search uses this strategy:

### Priority Order
1. **Equality filters** (can combine multiple):
   - `difficulty == "easy"`
   - `cuisine == "italian"`

2. **Array-contains** (special case):
   - `dietaryPreferences array-contains-any ["vegan", "gluten-free"]`

3. **ONE inequality filter**:
   - `cookTimeMinutes <= 30`

4. **Ordering**:
   - Must order by inequality field first
   - Then secondary sorting (requires index)

### Client-Side Filtering
For full-text search (title/description), we do client-side filtering since Firestore doesn't support it natively.

For production, consider:
- **Algolia** - Full-text search service
- **Elasticsearch** - Self-hosted search engine
- **Cloud Functions** - Server-side filtering

## Troubleshooting

### Index Already Exists
If you get "index already exists" error:
```bash
# Delete old indexes first
firebase firestore:indexes:delete <index-id>

# Then deploy new ones
firebase deploy --only firestore:indexes
```

### Index Building Takes Long
- Small collections: 1-2 minutes
- Large collections: 5-30 minutes
- Very large collections: Hours

Check status:
```bash
firebase firestore:indexes
```

### Query Still Fails After Creating Index
1. Wait 1-5 minutes for index to fully build
2. Check index status in Firebase Console
3. Verify your query matches the index exactly
4. Check that field names are spelled correctly

## Best Practices

### 1. Create Indexes Proactively
Don't wait for errors - create indexes during development.

### 2. Test Queries
Test your queries in Firebase Console's Firestore query builder.

### 3. Monitor Index Usage
Use Firebase Console to see which indexes are used most.

### 4. Clean Up Unused Indexes
Delete indexes that aren't being used to reduce storage costs.

### 5. Use Single-Field Indexes
For simple queries (one field), Firestore creates automatic indexes.

## Cost Considerations

- Each index takes storage space
- More indexes = higher storage costs
- Monitor index size in Firebase Console
- Delete unused indexes

## Further Reading

- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Query Limitations](https://firebase.google.com/docs/firestore/query-data/queries#query_limitations)
- [Index Best Practices](https://firebase.google.com/docs/firestore/query-data/index-overview)
