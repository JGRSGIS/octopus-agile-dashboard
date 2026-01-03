/**
 * LiveTab - Container component for real-time electricity monitoring
 */

import { AlertCircle, Radio, Wifi, WifiOff } from 'lucide-react';
import { useLiveDashboard, useLiveStatus } from '../hooks';
import LiveDemand from './LiveDemand';
import LiveConsumptionChart from './LiveConsumptionChart';
import LiveCostTracker from './LiveCostTracker';
import type { PricePeriod } from '../types';

interface LiveTabProps {
  currentPrice?: PricePeriod | null;
}

export function LiveTab({ currentPrice }: LiveTabProps) {
  // Check if Home Mini is available
  const { data: status, isLoading: statusLoading } = useLiveStatus();

  // Get live dashboard data (only if available)
  const {
    data: liveData,
    isLoading: dataLoading,
    error: dataError,
    isFetching,
  } = useLiveDashboard(status?.available ?? false);

  const isLoading = statusLoading || dataLoading;
  const priceValue = currentPrice?.value_inc_vat ?? null;

  // Not available state
  if (!statusLoading && !status?.available) {
    return (
      <div className="space-y-6">
        <div className="bg-gray-800/50 rounded-xl border border-yellow-600/50 p-8 text-center">
          <WifiOff className="w-16 h-16 text-yellow-500 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-200 mb-2">
            Home Mini Not Available
          </h3>
          <p className="text-gray-400 max-w-md mx-auto mb-4">
            {status?.message ||
              'Live monitoring requires an Octopus Home Mini device connected to your smart meter.'}
          </p>
          <div className="bg-gray-900/50 rounded-lg p-4 max-w-lg mx-auto text-left">
            <h4 className="text-sm font-medium text-gray-300 mb-2">To enable live monitoring:</h4>
            <ol className="text-sm text-gray-400 space-y-1 list-decimal list-inside">
              <li>Ensure you have an Octopus Home Mini installed</li>
              <li>
                Add your account number to the environment:
                <code className="ml-2 px-2 py-0.5 bg-gray-800 rounded text-blue-400">
                  OCTOPUS_ACCOUNT_NUMBER=A-XXXXXXXX
                </code>
              </li>
              <li>Restart the backend server</li>
            </ol>
          </div>
        </div>
      </div>
    );
  }

  // Error state
  if (dataError) {
    return (
      <div className="space-y-6">
        <div className="bg-gray-800/50 rounded-xl border border-red-600/50 p-8 text-center">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h3 className="text-xl font-semibold text-gray-200 mb-2">Error Loading Live Data</h3>
          <p className="text-gray-400">{dataError.message}</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Status banner */}
      <div className="bg-blue-900/30 border border-blue-600/50 rounded-xl p-4 flex items-center gap-4">
        <div className="bg-blue-500/20 rounded-full p-3">
          <Radio className="w-6 h-6 text-blue-400" />
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-blue-300">Live Monitoring Active</h3>
          <p className="text-sm text-gray-400">
            Receiving real-time data from your Home Mini every 10 seconds
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Wifi className={`w-5 h-5 ${isFetching ? 'text-blue-400 animate-pulse' : 'text-green-400'}`} />
          <span className="text-sm text-gray-400">
            {isFetching ? 'Updating...' : 'Connected'}
          </span>
        </div>
      </div>

      {/* Main content grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Live demand - left column */}
        <div className="lg:col-span-1">
          <LiveDemand
            current={liveData?.current ?? null}
            stats={liveData?.stats ?? null}
            isLoading={isLoading}
          />
        </div>

        {/* Cost tracker - right side */}
        <div className="lg:col-span-2">
          <LiveCostTracker
            stats={liveData?.stats ?? null}
            readings={liveData?.recent_readings ?? []}
            currentPrice={priceValue}
            isLoading={isLoading}
          />
        </div>
      </div>

      {/* Chart - full width */}
      <LiveConsumptionChart
        readings={liveData?.recent_readings ?? []}
        height={350}
        isLoading={isLoading}
      />

      {/* Stats summary */}
      {liveData?.stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* Current demand */}
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-500 mb-1">Current Demand</div>
            <div className="text-xl font-bold text-blue-400">
              {liveData.stats.demand?.current_watts !== null
                ? `${liveData.stats.demand.current_watts} W`
                : '--'}
            </div>
          </div>

          {/* Average demand */}
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-500 mb-1">5-Min Average</div>
            <div className="text-xl font-bold text-gray-300">
              {liveData.stats.demand?.average_kw !== undefined
                ? `${(liveData.stats.demand.average_kw * 1000).toFixed(0)} W`
                : '--'}
            </div>
          </div>

          {/* Session consumption */}
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-500 mb-1">Session Usage</div>
            <div className="text-xl font-bold text-emerald-400">
              {liveData.stats.consumption?.total_kwh !== undefined
                ? `${(liveData.stats.consumption.total_kwh * 1000).toFixed(1)} Wh`
                : '--'}
            </div>
          </div>

          {/* Session cost */}
          <div className="bg-gray-800/50 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-500 mb-1">Session Cost</div>
            <div className="text-xl font-bold text-yellow-400">
              {liveData.stats.cost?.total_pence !== undefined
                ? `${liveData.stats.cost.total_pence.toFixed(2)}p`
                : '--'}
            </div>
          </div>
        </div>
      )}

      {/* Footer note */}
      <div className="text-center text-xs text-gray-500">
        Data from Octopus Home Mini via GraphQL API • Updates every 10 seconds • Rate limit: 100 calls/hour
      </div>
    </div>
  );
}

export default LiveTab;
