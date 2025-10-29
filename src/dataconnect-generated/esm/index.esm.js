import { queryRef, executeQuery, mutationRef, executeMutation, validateArgs } from 'firebase/data-connect';

export const connectorConfig = {
  connector: 'example',
  service: 'projetweb',
  location: 'us-east4'
};

export const addIngredientToFridgeRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddIngredientToFridge', inputVars);
}
addIngredientToFridgeRef.operationName = 'AddIngredientToFridge';

export function addIngredientToFridge(dcOrVars, vars) {
  return executeMutation(addIngredientToFridgeRef(dcOrVars, vars));
}

export const getUserFridgeRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetUserFridge', inputVars);
}
getUserFridgeRef.operationName = 'GetUserFridge';

export function getUserFridge(dcOrVars, vars) {
  return executeQuery(getUserFridgeRef(dcOrVars, vars));
}

export const addMealPlanRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddMealPlan', inputVars);
}
addMealPlanRef.operationName = 'AddMealPlan';

export function addMealPlan(dcOrVars, vars) {
  return executeMutation(addMealPlanRef(dcOrVars, vars));
}

export const getUserMealPlanRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetUserMealPlan', inputVars);
}
getUserMealPlanRef.operationName = 'GetUserMealPlan';

export function getUserMealPlan(dcOrVars, vars) {
  return executeQuery(getUserMealPlanRef(dcOrVars, vars));
}

