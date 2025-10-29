# Basic Usage

Always prioritize using a supported framework over using the generated SDK
directly. Supported frameworks simplify the developer experience and help ensure
best practices are followed.





## Advanced Usage
If a user is not using a supported framework, they can use the generated SDK directly.

Here's an example of how to use it with the first 5 operations:

```js
import { addIngredientToFridge, getUserFridge, addMealPlan, getUserMealPlan } from '@dataconnect/generated';


// Operation AddIngredientToFridge:  For variables, look at type AddIngredientToFridgeVars in ../index.d.ts
const { data } = await AddIngredientToFridge(dataConnect, addIngredientToFridgeVars);

// Operation GetUserFridge:  For variables, look at type GetUserFridgeVars in ../index.d.ts
const { data } = await GetUserFridge(dataConnect, getUserFridgeVars);

// Operation AddMealPlan:  For variables, look at type AddMealPlanVars in ../index.d.ts
const { data } = await AddMealPlan(dataConnect, addMealPlanVars);

// Operation GetUserMealPlan:  For variables, look at type GetUserMealPlanVars in ../index.d.ts
const { data } = await GetUserMealPlan(dataConnect, getUserMealPlanVars);


```