import React from 'react';
import { dateUtils } from '../utils/dateUtils';

const NutritionTrackerPage = () => {
  const today = dateUtils.today();

  return (
    <section id="nutrition-tracker-page" className="page">
      <div className="container">
        <div className="page-header">
          <h1>Nutrition Tracker</h1>
          <p>Monitor your daily nutrition and track progress towards your health goals</p>
        </div>

        <div className="nutrition-dashboard">
          <div className="dashboard-controls">
            <div className="date-selector">
              <button className="btn btn-outline" title="Previous day">
                <i className="fas fa-chevron-left"></i>
              </button>
              <input type="date" id="tracking-date" defaultValue={today} />
              <button className="btn btn-outline" title="Next day">
                <i className="fas fa-chevron-right"></i>
              </button>
            </div>
            <button className="btn btn-primary">
              <i className="fas fa-target"></i>
              Set Goals
            </button>
          </div>

          <div className="nutrition-overview" id="nutrition-overview">
            {/* Daily nutrition summary */}
          </div>
        </div>
      </div>
    </section>
  );
};

export default NutritionTrackerPage;
