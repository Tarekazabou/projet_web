import { ConnectorConfig, DataConnect, QueryRef, QueryPromise, MutationRef, MutationPromise } from 'firebase/data-connect';

export const connectorConfig: ConnectorConfig;

export type TimestampString = string;
export type UUIDString = string;
export type Int64String = string;
export type DateString = string;




export interface AddIngredientToFridgeData {
  fridgeItem_insert: FridgeItem_Key;
}

export interface AddIngredientToFridgeVariables {
  userId: UUIDString;
  ingredientId: UUIDString;
  quantity: number;
  unit: string;
  expirationDate?: DateString | null;
}

export interface AddMealPlanData {
  mealPlan_insert: MealPlan_Key;
}

export interface AddMealPlanVariables {
  userId: UUIDString;
  recipeId: UUIDString;
  mealType: string;
  planDate: DateString;
}

export interface FridgeItem_Key {
  userId: UUIDString;
  ingredientId: UUIDString;
  __typename?: 'FridgeItem_Key';
}

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

export interface GetUserFridgeVariables {
  userId: UUIDString;
}

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

export interface GetUserMealPlanVariables {
  userId: UUIDString;
  planDate: DateString;
}

export interface Ingredient_Key {
  id: UUIDString;
  __typename?: 'Ingredient_Key';
}

export interface MealPlan_Key {
  id: UUIDString;
  __typename?: 'MealPlan_Key';
}

export interface RecipeIngredient_Key {
  recipeId: UUIDString;
  ingredientId: UUIDString;
  __typename?: 'RecipeIngredient_Key';
}

export interface Recipe_Key {
  id: UUIDString;
  __typename?: 'Recipe_Key';
}

export interface User_Key {
  id: UUIDString;
  __typename?: 'User_Key';
}

interface AddIngredientToFridgeRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddIngredientToFridgeVariables): MutationRef<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: AddIngredientToFridgeVariables): MutationRef<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;
  operationName: string;
}
export const addIngredientToFridgeRef: AddIngredientToFridgeRef;

export function addIngredientToFridge(vars: AddIngredientToFridgeVariables): MutationPromise<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;
export function addIngredientToFridge(dc: DataConnect, vars: AddIngredientToFridgeVariables): MutationPromise<AddIngredientToFridgeData, AddIngredientToFridgeVariables>;

interface GetUserFridgeRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetUserFridgeVariables): QueryRef<GetUserFridgeData, GetUserFridgeVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetUserFridgeVariables): QueryRef<GetUserFridgeData, GetUserFridgeVariables>;
  operationName: string;
}
export const getUserFridgeRef: GetUserFridgeRef;

export function getUserFridge(vars: GetUserFridgeVariables): QueryPromise<GetUserFridgeData, GetUserFridgeVariables>;
export function getUserFridge(dc: DataConnect, vars: GetUserFridgeVariables): QueryPromise<GetUserFridgeData, GetUserFridgeVariables>;

interface AddMealPlanRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: AddMealPlanVariables): MutationRef<AddMealPlanData, AddMealPlanVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: AddMealPlanVariables): MutationRef<AddMealPlanData, AddMealPlanVariables>;
  operationName: string;
}
export const addMealPlanRef: AddMealPlanRef;

export function addMealPlan(vars: AddMealPlanVariables): MutationPromise<AddMealPlanData, AddMealPlanVariables>;
export function addMealPlan(dc: DataConnect, vars: AddMealPlanVariables): MutationPromise<AddMealPlanData, AddMealPlanVariables>;

interface GetUserMealPlanRef {
  /* Allow users to create refs without passing in DataConnect */
  (vars: GetUserMealPlanVariables): QueryRef<GetUserMealPlanData, GetUserMealPlanVariables>;
  /* Allow users to pass in custom DataConnect instances */
  (dc: DataConnect, vars: GetUserMealPlanVariables): QueryRef<GetUserMealPlanData, GetUserMealPlanVariables>;
  operationName: string;
}
export const getUserMealPlanRef: GetUserMealPlanRef;

export function getUserMealPlan(vars: GetUserMealPlanVariables): QueryPromise<GetUserMealPlanData, GetUserMealPlanVariables>;
export function getUserMealPlan(dc: DataConnect, vars: GetUserMealPlanVariables): QueryPromise<GetUserMealPlanData, GetUserMealPlanVariables>;

