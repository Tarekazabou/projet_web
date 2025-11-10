import React from 'react';

const MealPlannerPage = () => {
  return (
    <section id="meal-planner-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1>Smart Meal Planner</h1>
          <p>Create balanced weekly meal plans tailored to your nutritional goals</p>
        </div>

        <div className="meal-planner-container">
          <div className="planner-controls">
            <div className="controls-row">
              <div className="date-picker">
                <label htmlFor="plan-start-date">Start Date</label>
                <input type="date" id="plan-start-date" />
              </div>
              <div className="plan-type">
                <label htmlFor="plan-duration">Duration</label>
                <select id="plan-duration">
                  <option value="7">1 Week</option>
                  <option value="14">2 Weeks</option>
                  <option value="30">1 Month</option>
                </select>
              </div>
              <button className="btn btn-primary">
                <i className="fas fa-calendar-plus"></i>
                Generate Plan
              </button>
            </div>
          </div>

          <div className="meal-timeline" id="meal-timeline">
            {/* Meal timeline will be generated here */}
          </div>
        </div>
      </div>
    </section>
  );
};

export default MealPlannerPage;
