const { queryRef, executeQuery, mutationRef, executeMutation, validateArgs } = require('firebase/data-connect');

const connectorConfig = {
  connector: 'example',
  service: 'projetweb',
  location: 'us-east4'
};
exports.connectorConfig = connectorConfig;

const addIngredientToFridgeRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddIngredientToFridge', inputVars);
}
addIngredientToFridgeRef.operationName = 'AddIngredientToFridge';
exports.addIngredientToFridgeRef = addIngredientToFridgeRef;

exports.addIngredientToFridge = function addIngredientToFridge(dcOrVars, vars) {
  return executeMutation(addIngredientToFridgeRef(dcOrVars, vars));
};

const getUserFridgeRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetUserFridge', inputVars);
}
getUserFridgeRef.operationName = 'GetUserFridge';
exports.getUserFridgeRef = getUserFridgeRef;

exports.getUserFridge = function getUserFridge(dcOrVars, vars) {
  return executeQuery(getUserFridgeRef(dcOrVars, vars));
};

const addMealPlanRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return mutationRef(dcInstance, 'AddMealPlan', inputVars);
}
addMealPlanRef.operationName = 'AddMealPlan';
exports.addMealPlanRef = addMealPlanRef;

exports.addMealPlan = function addMealPlan(dcOrVars, vars) {
  return executeMutation(addMealPlanRef(dcOrVars, vars));
};

const getUserMealPlanRef = (dcOrVars, vars) => {
  const { dc: dcInstance, vars: inputVars} = validateArgs(connectorConfig, dcOrVars, vars, true);
  dcInstance._useGeneratedSdk();
  return queryRef(dcInstance, 'GetUserMealPlan', inputVars);
}
getUserMealPlanRef.operationName = 'GetUserMealPlan';
exports.getUserMealPlanRef = getUserMealPlanRef;

exports.getUserMealPlan = function getUserMealPlan(dcOrVars, vars) {
  return executeQuery(getUserMealPlanRef(dcOrVars, vars));
};
