# Generated TypeScript README
This README will guide you through the process of using the generated JavaScript SDK package for the connector `example`. It will also provide examples on how to use your generated SDK to call your Data Connect queries and mutations.

***NOTE:** This README is generated alongside the generated SDK. If you make changes to this file, they will be overwritten when the SDK is regenerated.*

# Table of Contents
- [**Overview**](#generated-javascript-readme)
- [**Accessing the connector**](#accessing-the-connector)
  - [*Connecting to the local Emulator*](#connecting-to-the-local-emulator)
- [**Queries**](#queries)
  - [*GetUserFridge*](#getuserfridge)
  - [*GetUserMealPlan*](#getusermealplan)
- [**Mutations**](#mutations)
  - [*AddIngredientToFridge*](#addingredienttofridge)
  - [*AddMealPlan*](#addmealplan)

# Accessing the connector
A connector is a collection of Queries and Mutations. One SDK is generated for each connector - this SDK is generated for the connector `example`. You can find more information about connectors in the [Data Connect documentation](https://firebase.google.com/docs/data-connect#how-does).

You can use this generated SDK by importing from the package `@dataconnect/generated` as shown below. Both CommonJS and ESM imports are supported.

You can also follow the instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#set-client).

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
```

## Connecting to the local Emulator
By default, the connector will connect to the production service.

To connect to the emulator, you can use the following code.
You can also follow the emulator instructions from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#instrument-clients).

```typescript
import { connectDataConnectEmulator, getDataConnect } from 'firebase/data-connect';
import { connectorConfig } from '@dataconnect/generated';

const dataConnect = getDataConnect(connectorConfig);
connectDataConnectEmulator(dataConnect, 'localhost', 9399);
```

After it's initialized, you can call your Data Connect [queries](#queries) and [mutations](#mutations) from your generated SDK.

# Queries

There are two ways to execute a Data Connect Query using the generated Web SDK:
- Using a Query Reference function, which returns a `QueryRef`
  - The `QueryRef` can be used as an argument to `executeQuery()`, which will execute the Query and return a `QueryPromise`
- Using an action shortcut function, which returns a `QueryPromise`
  - Calling the action shortcut function will execute the Query and return a `QueryPromise`

The following is true for both the action shortcut function and the `QueryRef` function:
- The `QueryPromise` returned will resolve to the result of the Query once it has finished executing
- If the Query accepts arguments, both the action shortcut function and the `QueryRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Query
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each query. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-queries).

## GetUserFridge
You can execute the `GetUserFridge` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getUserFridge(vars: GetUserFridgeVariables): QueryPromise<GetUserFridgeData, GetUserFridgeVariables>;

interface GetUserFridgeRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetUserFridgeVariables): QueryRef<GetUserFridgeData, GetUserFridgeVariables>;
}
export const getUserFridgeRef: GetUserFridgeRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getUserFridge(dc: DataConnect, vars: GetUserFridgeVariables): QueryPromise<GetUserFridgeData, GetUserFridgeVariables>;

interface GetUserFridgeRef {
  ...
  (dc: DataConnect, vars: GetUserFridgeVariables): QueryRef<GetUserFridgeData, GetUserFridgeVariables>;
}
export const getUserFridgeRef: GetUserFridgeRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getUserFridgeRef:
```typescript
const name = getUserFridgeRef.operationName;
console.log(name);
```

### Variables
The `GetUserFridge` query requires an argument of type `GetUserFridgeVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface GetUserFridgeVariables {
  userId: UUIDString;
}
```
### Return Type
Recall that executing the `GetUserFridge` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetUserFridgeData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetUserFridgeData {
  fridgeItems: ({
    ingredient: {
      id: UUIDString;
      name: string;
      unit: string;
    } & Ingredient_Key;
      quantity: number;
      unit: string;
      expirationDate?: DateString | null;
  })[];
}
```
### Using `GetUserFridge`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getUserFridge, GetUserFridgeVariables } from '@dataconnect/generated';

// The `GetUserFridge` query requires an argument of type `GetUserFridgeVariables`:
const getUserFridgeVars: GetUserFridgeVariables = {
  userId: ..., 
};

// Call the `getUserFridge()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getUserFridge(getUserFridgeVars);
// Variables can be defined inline as well.
const { data } = await getUserFridge({ userId: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getUserFridge(dataConnect, getUserFridgeVars);

console.log(data.fridgeItems);

// Or, you can use the `Promise` API.
getUserFridge(getUserFridgeVars).then((response) => {
  const data = response.data;
  console.log(data.fridgeItems);
});
```

### Using `GetUserFridge`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getUserFridgeRef, GetUserFridgeVariables } from '@dataconnect/generated';

// The `GetUserFridge` query requires an argument of type `GetUserFridgeVariables`:
const getUserFridgeVars: GetUserFridgeVariables = {
  userId: ..., 
};

// Call the `getUserFridgeRef()` function to get a reference to the query.
const ref = getUserFridgeRef(getUserFridgeVars);
// Variables can be defined inline as well.
const ref = getUserFridgeRef({ userId: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getUserFridgeRef(dataConnect, getUserFridgeVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.fridgeItems);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.fridgeItems);
});
```

## GetUserMealPlan
You can execute the `GetUserMealPlan` query using the following action shortcut function, or by calling `executeQuery()` after calling the following `QueryRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
getUserMealPlan(vars: GetUserMealPlanVariables): QueryPromise<GetUserMealPlanData, GetUserMealPlanVariables>;

interface GetUserMealPlanRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetUserMealPlanVariables): QueryRef<GetUserMealPlanData, GetUserMealPlanVariables>;
}
export const getUserMealPlanRef: GetUserMealPlanRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `QueryRef` function.
```typescript
getUserMealPlan(dc: DataConnect, vars: GetUserMealPlanVariables): QueryPromise<GetUserMealPlanData, GetUserMealPlanVariables>;

interface GetUserMealPlanRef {
  ...
  (dc: DataConnect, vars: GetUserMealPlanVariables): QueryRef<GetUserMealPlanData, GetUserMealPlanVariables>;
}
export const getUserMealPlanRef: GetUserMealPlanRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the getUserMealPlanRef:
```typescript
const name = getUserMealPlanRef.operationName;
console.log(name);
```

### Variables
The `GetUserMealPlan` query requires an argument of type `GetUserMealPlanVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface GetUserMealPlanVariables {
  userId: UUIDString;
  planDate: DateString;
}
```
### Return Type
Recall that executing the `GetUserMealPlan` query returns a `QueryPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `GetUserMealPlanData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface GetUserMealPlanData {
  mealPlans: ({
    id: UUIDString;
    recipe: {
      id: UUIDString;
      title: string;
      imageUrl?: string | null;
    } & Recipe_Key;
      mealType: string;
      planDate: DateString;
  } & MealPlan_Key)[];
}
```
### Using `GetUserMealPlan`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, getUserMealPlan, GetUserMealPlanVariables } from '@dataconnect/generated';

// The `GetUserMealPlan` query requires an argument of type `GetUserMealPlanVariables`:
const getUserMealPlanVars: GetUserMealPlanVariables = {
  userId: ..., 
  planDate: ..., 
};

// Call the `getUserMealPlan()` function to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await getUserMealPlan(getUserMealPlanVars);
// Variables can be defined inline as well.
const { data } = await getUserMealPlan({ userId: ..., planDate: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await getUserMealPlan(dataConnect, getUserMealPlanVars);

console.log(data.mealPlans);

// Or, you can use the `Promise` API.
getUserMealPlan(getUserMealPlanVars).then((response) => {
  const data = response.data;
  console.log(data.mealPlans);
});
```

### Using `GetUserMealPlan`'s `QueryRef` function

```typescript
import { getDataConnect, executeQuery } from 'firebase/data-connect';
import { connectorConfig, getUserMealPlanRef, GetUserMealPlanVariables } from '@dataconnect/generated';

// The `GetUserMealPlan` query requires an argument of type `GetUserMealPlanVariables`:
const getUserMealPlanVars: GetUserMealPlanVariables = {
  userId: ..., 
  planDate: ..., 
};

// Call the `getUserMealPlanRef()` function to get a reference to the query.
const ref = getUserMealPlanRef(getUserMealPlanVars);
// Variables can be defined inline as well.
const ref = getUserMealPlanRef({ userId: ..., planDate: ..., });

// You can also pass in a `DataConnect` instance to the `QueryRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = getUserMealPlanRef(dataConnect, getUserMealPlanVars);

// Call `executeQuery()` on the reference to execute the query.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeQuery(ref);

console.log(data.mealPlans);

// Or, you can use the `Promise` API.
executeQuery(ref).then((response) => {
  const data = response.data;
  console.log(data.mealPlans);
});
```

# Mutations

There are two ways to execute a Data Connect Mutation using the generated Web SDK:
- Using a Mutation Reference function, which returns a `MutationRef`
  - The `MutationRef` can be used as an argument to `executeMutation()`, which will execute the Mutation and return a `MutationPromise`
- Using an action shortcut function, which returns a `MutationPromise`
  - Calling the action shortcut function will execute the Mutation and return a `MutationPromise`

The following is true for both the action shortcut function and the `MutationRef` function:
- The `MutationPromise` returned will resolve to the result of the Mutation once it has finished executing
- If the Mutation accepts arguments, both the action shortcut function and the `MutationRef` function accept a single argument: an object that contains all the required variables (and the optional variables) for the Mutation
- Both functions can be called with or without passing in a `DataConnect` instance as an argument. If no `DataConnect` argument is passed in, then the generated SDK will call `getDataConnect(connectorConfig)` behind the scenes for you.

Below are examples of how to use the `example` connector's generated functions to execute each mutation. You can also follow the examples from the [Data Connect documentation](https://firebase.google.com/docs/data-connect/web-sdk#using-mutations).

## AddIngredientToFridge
You can execute the `AddIngredientToFridge` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
addIngredientToFridge(vars: AddIngredientToFridgeVariables): MutationPromise<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;

interface AddIngredientToFridgeRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddIngredientToFridgeVariables): MutationRef<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;
}
export const addIngredientToFridgeRef: AddIngredientToFridgeRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
addIngredientToFridge(dc: DataConnect, vars: AddIngredientToFridgeVariables): MutationPromise<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;

interface AddIngredientToFridgeRef {
  ...
  (dc: DataConnect, vars: AddIngredientToFridgeVariables): MutationRef<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;
}
export const addIngredientToFridgeRef: AddIngredientToFridgeRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the addIngredientToFridgeRef:
```typescript
const name = addIngredientToFridgeRef.operationName;
console.log(name);
```

### Variables
The `AddIngredientToFridge` mutation requires an argument of type `AddIngredientToFridgeVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface AddIngredientToFridgeVariables {
  userId: UUIDString;
  ingredientId: UUIDString;
  quantity: number;
  unit: string;
  expirationDate?: DateString | null;
}
```
### Return Type
Recall that executing the `AddIngredientToFridge` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `AddIngredientToFridgeData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface AddIngredientToFridgeData {
  fridgeItem_insert: FridgeItem_Key;
}
```
### Using `AddIngredientToFridge`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, addIngredientToFridge, AddIngredientToFridgeVariables } from '@dataconnect/generated';

// The `AddIngredientToFridge` mutation requires an argument of type `AddIngredientToFridgeVariables`:
const addIngredientToFridgeVars: AddIngredientToFridgeVariables = {
  userId: ..., 
  ingredientId: ..., 
  quantity: ..., 
  unit: ..., 
  expirationDate: ..., // optional
};

// Call the `addIngredientToFridge()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await addIngredientToFridge(addIngredientToFridgeVars);
// Variables can be defined inline as well.
const { data } = await addIngredientToFridge({ userId: ..., ingredientId: ..., quantity: ..., unit: ..., expirationDate: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await addIngredientToFridge(dataConnect, addIngredientToFridgeVars);

console.log(data.fridgeItem_insert);

// Or, you can use the `Promise` API.
addIngredientToFridge(addIngredientToFridgeVars).then((response) => {
  const data = response.data;
  console.log(data.fridgeItem_insert);
});
```

### Using `AddIngredientToFridge`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, addIngredientToFridgeRef, AddIngredientToFridgeVariables } from '@dataconnect/generated';

// The `AddIngredientToFridge` mutation requires an argument of type `AddIngredientToFridgeVariables`:
const addIngredientToFridgeVars: AddIngredientToFridgeVariables = {
  userId: ..., 
  ingredientId: ..., 
  quantity: ..., 
  unit: ..., 
  expirationDate: ..., // optional
};

// Call the `addIngredientToFridgeRef()` function to get a reference to the mutation.
const ref = addIngredientToFridgeRef(addIngredientToFridgeVars);
// Variables can be defined inline as well.
const ref = addIngredientToFridgeRef({ userId: ..., ingredientId: ..., quantity: ..., unit: ..., expirationDate: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = addIngredientToFridgeRef(dataConnect, addIngredientToFridgeVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.fridgeItem_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.fridgeItem_insert);
});
```

## AddMealPlan
You can execute the `AddMealPlan` mutation using the following action shortcut function, or by calling `executeMutation()` after calling the following `MutationRef` function, both of which are defined in [dataconnect-generated/index.d.ts](./index.d.ts):
```typescript
addMealPlan(vars: AddMealPlanVariables): MutationPromise<AddMealPlanData, AddMealPlanVariables>;

interface AddMealPlanRef {
  ...
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddMealPlanVariables): MutationRef<AddMealPlanData, AddMealPlanVariables>;
}
export const addMealPlanRef: AddMealPlanRef;
```
You can also pass in a `DataConnect` instance to the action shortcut function or `MutationRef` function.
```typescript
addMealPlan(dc: DataConnect, vars: AddMealPlanVariables): MutationPromise<AddMealPlanData, AddMealPlanVariables>;

interface AddMealPlanRef {
  ...
  (dc: DataConnect, vars: AddMealPlanVariables): MutationRef<AddMealPlanData, AddMealPlanVariables>;
}
export const addMealPlanRef: AddMealPlanRef;
```

If you need the name of the operation without creating a ref, you can retrieve the operation name by calling the `operationName` property on the addMealPlanRef:
```typescript
const name = addMealPlanRef.operationName;
console.log(name);
```

### Variables
The `AddMealPlan` mutation requires an argument of type `AddMealPlanVariables`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:

```typescript
export interface AddMealPlanVariables {
  userId: UUIDString;
  recipeId: UUIDString;
  mealType: string;
  planDate: DateString;
}
```
### Return Type
Recall that executing the `AddMealPlan` mutation returns a `MutationPromise` that resolves to an object with a `data` property.

The `data` property is an object of type `AddMealPlanData`, which is defined in [dataconnect-generated/index.d.ts](./index.d.ts). It has the following fields:
```typescript
export interface AddMealPlanData {
  mealPlan_insert: MealPlan_Key;
}
```
### Using `AddMealPlan`'s action shortcut function

```typescript
import { getDataConnect } from 'firebase/data-connect';
import { connectorConfig, addMealPlan, AddMealPlanVariables } from '@dataconnect/generated';

// The `AddMealPlan` mutation requires an argument of type `AddMealPlanVariables`:
const addMealPlanVars: AddMealPlanVariables = {
  userId: ..., 
  recipeId: ..., 
  mealType: ..., 
  planDate: ..., 
};

// Call the `addMealPlan()` function to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await addMealPlan(addMealPlanVars);
// Variables can be defined inline as well.
const { data } = await addMealPlan({ userId: ..., recipeId: ..., mealType: ..., planDate: ..., });

// You can also pass in a `DataConnect` instance to the action shortcut function.
const dataConnect = getDataConnect(connectorConfig);
const { data } = await addMealPlan(dataConnect, addMealPlanVars);

console.log(data.mealPlan_insert);

// Or, you can use the `Promise` API.
addMealPlan(addMealPlanVars).then((response) => {
  const data = response.data;
  console.log(data.mealPlan_insert);
});
```

### Using `AddMealPlan`'s `MutationRef` function

```typescript
import { getDataConnect, executeMutation } from 'firebase/data-connect';
import { connectorConfig, addMealPlanRef, AddMealPlanVariables } from '@dataconnect/generated';

// The `AddMealPlan` mutation requires an argument of type `AddMealPlanVariables`:
const addMealPlanVars: AddMealPlanVariables = {
  userId: ..., 
  recipeId: ..., 
  mealType: ..., 
  planDate: ..., 
};

// Call the `addMealPlanRef()` function to get a reference to the mutation.
const ref = addMealPlanRef(addMealPlanVars);
// Variables can be defined inline as well.
const ref = addMealPlanRef({ userId: ..., recipeId: ..., mealType: ..., planDate: ..., });

// You can also pass in a `DataConnect` instance to the `MutationRef` function.
const dataConnect = getDataConnect(connectorConfig);
const ref = addMealPlanRef(dataConnect, addMealPlanVars);

// Call `executeMutation()` on the reference to execute the mutation.
// You can use the `await` keyword to wait for the promise to resolve.
const { data } = await executeMutation(ref);

console.log(data.mealPlan_insert);

// Or, you can use the `Promise` API.
executeMutation(ref).then((response) => {
  const data = response.data;
  console.log(data.mealPlan_insert);
});
```

