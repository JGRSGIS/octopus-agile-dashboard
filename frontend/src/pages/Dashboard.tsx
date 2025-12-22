/**
 * Main Dashboard page component
 */

import { useState } from 'react';
import { RefreshCw, AlertCircle, Zap, Clock } from 'lucide-react';

import { useDashboard, useHealth } from '../hooks';
import CurrentPrice from '../components/CurrentPrice';
import PriceChart from '../components/PriceChart';
import StatsCards from '../components/StatsCards';
import DataTable from '../components/DataTable';
import { formatRelativeTime } from '../utils/formatters';

type TabType = 'overview' | 'prices' | 'consumption' | 'analysis';

export function Dashboard() {
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  
  // Fetch dashboard data
  const {
    data: dashboardData,
    isLoading,
    error,
    refetch,
    dataUpdatedAt,
  } = useDashboard();

  // Health check
  const { data: health, isLoading: healthLoading } = useHealth();

  // Handle refresh
  const handleRefresh = () => {
    refetch();
  };

  // Loading state
  if (isLoading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-16 w-16 border-t-2 border-b-2 border-blue-500 mx-auto mb-4"></div>
          <p className="text-gray-400">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center max-w-md mx-auto p-6">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-xl font-semibold text-gray-200 mb-2">
            Unable to Load Dashboard
          </h2>
          <p className="text-gray-400 mb-4">{error.message}</p>
          <button
            onClick={handleRefresh}
            className="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-white transition-colors"
          >
            Try Again
          </button>
        </div>
      </div>
    );
  }

  // No data state
  if (!dashboardData) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-400">No data available</p>
          <button
            onClick={handleRefresh}
            className="mt-4 px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg text-white transition-colors"
          >
            Refresh
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      {/* Header */}
      <header className="bg-gray-800 border-b border-gray-700 sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Zap className="w-8 h-8 text-yellow-400" />
              <div>
                <h1 className="text-xl font-bold">Octopus Agile Dashboard</h1>
                <p className="text-xs text-gray-400">
                  Region {dashboardData.region} • Southampton, Hampshire
                </p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              {/* Last updated */}
              <div className="text-sm text-gray-400 flex items-center gap-1">
                <Clock className="w-4 h-4" />
                <span>
                  Updated {dataUpdatedAt ? formatRelativeTime(new Date(dataUpdatedAt)) : 'never'}
                </span>
              </div>

              {/* Health indicator */}
              <div className="flex items-center gap-1">
                <div
                  className={`w-2 h-2 rounded-full ${
                    healthLoading
                      ? 'bg-yellow-400 animate-pulse'
                      : health?.status === 'healthy'
                      ? 'bg-green-400'
                      : 'bg-red-400'
                  }`}
                />
                <span className="text-xs text-gray-400">
                  {healthLoading ? 'Checking...' : health?.status || 'Unknown'}
                </span>
              </div>

              {/* Refresh button */}
              <button
                onClick={handleRefresh}
                className="p-2 hover:bg-gray-700 rounded-lg transition-colors"
                title="Refresh data"
              >
                <RefreshCw className="w-5 h-5" />
              </button>
            </div>
          </div>

          {/* Navigation tabs */}
          <nav className="flex gap-1 mt-4 -mb-4">
            {(['overview', 'prices', 'consumption', 'analysis'] as TabType[]).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-4 py-2 rounded-t-lg font-medium transition-colors ${
                  activeTab === tab
                    ? 'bg-gray-900 text-white border-t border-x border-gray-700'
                    : 'text-gray-400 hover:text-gray-200 hover:bg-gray-700/50'
                }`}
              >
                {tab.charAt(0).toUpperCase() + tab.slice(1)}
              </button>
            ))}
          </nav>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-7xl mx-auto px-4 py-6">
        {/* Negative price alert banner */}
        {dashboardData.has_negative_upcoming && (
          <div className="bg-emerald-900/50 border border-emerald-500 rounded-xl p-4 mb-6 flex items-center gap-4">
            <div className="bg-emerald-500 rounded-full p-3 animate-pulse">
              <Zap className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="font-bold text-emerald-400 text-lg">
                🎉 Negative Prices Coming!
              </h3>
              <p className="text-gray-300">
                You'll get PAID to use electricity during upcoming periods. Check the best times below!
              </p>
            </div>
          </div>
        )}

        {/* Tab content */}
        {activeTab === 'overview' && (
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Current price - left column on desktop */}
            <div className="lg:col-span-1">
              <CurrentPrice
                currentPrice={dashboardData.current_price}
                bestUpcoming={dashboardData.best_upcoming}
                hasNegativeUpcoming={dashboardData.has_negative_upcoming}
              />
            </div>

            {/* Charts and stats - right columns */}
            <div className="lg:col-span-2 space-y-6">
              {/* Price chart */}
              <PriceChart
                prices={dashboardData.prices_48h}
                consumption={dashboardData.consumption_7d}
                title="48-Hour Price View"
                height={350}
              />

              {/* Stats cards */}
              <StatsCards
                priceStats={dashboardData.today.prices}
                consumptionStats={dashboardData.today.consumption}
                costAnalysis={dashboardData.cost_analysis}
              />
            </div>
          </div>
        )}

        {activeTab === 'prices' && (
          <div className="space-y-6">
            <PriceChart
              prices={dashboardData.prices_48h}
              title="Agile Prices - 48 Hour View"
              height={450}
              showConsumption={false}
            />

            <StatsCards priceStats={dashboardData.today.prices} />

            <DataTable data={dashboardData.prices_48h} type="prices" height={500} />
          </div>
        )}

        {activeTab === 'consumption' && (
          <div className="space-y-6">
            <PriceChart
              prices={[]}
              consumption={dashboardData.consumption_7d}
              title="Consumption - Last 7 Days"
              height={450}
              showConsumption={true}
            />

            <StatsCards consumptionStats={dashboardData.today.consumption} />

            <DataTable
              data={dashboardData.consumption_7d}
              type="consumption"
              height={500}
            />
          </div>
        )}

        {activeTab === 'analysis' && (
          <div className="space-y-6">
            <PriceChart
              prices={dashboardData.prices_48h}
              consumption={dashboardData.consumption_7d}
              title="Price vs Consumption Analysis"
              height={450}
              showConsumption={true}
            />

            <StatsCards
              priceStats={dashboardData.today.prices}
              consumptionStats={dashboardData.today.consumption}
              costAnalysis={dashboardData.cost_analysis}
            />

            <DataTable
              data={dashboardData.cost_analysis.cost_by_period}
              type="cost"
              height={500}
            />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-gray-800 border-t border-gray-700 mt-auto">
        <div className="max-w-7xl mx-auto px-4 py-4">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-2 text-sm text-gray-400">
            <p>
              Data from{' '}
              <a
                href="https://octopus.energy"
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-400 hover:underline"
              >
                Octopus Energy
              </a>{' '}
              API
            </p>
            <p>
              Prices update every 30 minutes • Consumption may have 24-48h delay
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default Dashboard;
