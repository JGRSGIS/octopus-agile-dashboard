/**
 * LiveCostTracker - Displays running cost based on live consumption
 */

import { PoundSterling, Zap, Clock, TrendingUp } from 'lucide-react';
import type { TelemetrySummary, TelemetryReading } from '../types';

interface LiveCostTrackerProps {
  stats: TelemetrySummary | null;
  readings: TelemetryReading[];
  currentPrice?: number | null; // Current Agile price in p/kWh
  isLoading?: boolean;
}

// Format cost for display
function formatCost(pence: number): string {
  if (pence >= 100) {
    return `£${(pence / 100).toFixed(2)}`;
  }
  return `${pence.toFixed(2)}p`;
}

// Calculate estimated hourly cost from current demand
function estimateHourlyCost(demandKw: number | null, pricePerKwh: number | null): number | null {
  if (demandKw === null || pricePerKwh === null) return null;
  return demandKw * pricePerKwh; // pence per hour
}

// Calculate daily estimate from hourly
function estimateDailyCost(hourlyPence: number | null): number | null {
  if (hourlyPence === null) return null;
  return hourlyPence * 24;
}

export function LiveCostTracker({
  stats,
  readings,
  currentPrice,
  isLoading,
}: LiveCostTrackerProps) {
  // Get current demand for estimates
  const currentDemandKw = stats?.demand?.current_kw ?? null;
  const avgDemandKw = stats?.demand?.average_kw ?? null;

  // Calculate costs
  const sessionCost = stats?.cost?.total_pence ?? null;
  const sessionKwh = stats?.consumption?.total_kwh ?? null;
  const hourlyCostEstimate = estimateHourlyCost(currentDemandKw, currentPrice ?? null);
  const dailyCostEstimate = estimateDailyCost(hourlyCostEstimate);
  const avgHourlyCost = estimateHourlyCost(avgDemandKw ?? null, currentPrice ?? null);

  // Count readings in the session
  const readingCount = readings.length;
  const sessionMinutes = readingCount > 0 ? Math.round((readingCount * 10) / 60) : 0;

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <PoundSterling className="w-5 h-5 text-emerald-400" />
          <h3 className="text-lg font-semibold text-gray-200">Live Cost Tracker</h3>
        </div>
        {isLoading && (
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            <span className="text-xs text-gray-500">Updating...</span>
          </div>
        )}
      </div>

      {/* Main cost cards */}
      <div className="grid grid-cols-2 gap-4 mb-6">
        {/* Session cost */}
        <div className="bg-gray-900/50 rounded-lg p-4">
          <div className="flex items-center gap-2 text-gray-400 text-sm mb-2">
            <Clock className="w-4 h-4" />
            <span>Session ({sessionMinutes} min)</span>
          </div>
          <div className="text-2xl font-bold text-emerald-400">
            {sessionCost !== null ? formatCost(sessionCost) : '--'}
          </div>
          {sessionKwh !== null && (
            <div className="text-xs text-gray-500 mt-1">{sessionKwh.toFixed(4)} kWh used</div>
          )}
        </div>

        {/* Hourly estimate */}
        <div className="bg-gray-900/50 rounded-lg p-4">
          <div className="flex items-center gap-2 text-gray-400 text-sm mb-2">
            <TrendingUp className="w-4 h-4" />
            <span>Current Rate</span>
          </div>
          <div className="text-2xl font-bold text-blue-400">
            {hourlyCostEstimate !== null ? `${hourlyCostEstimate.toFixed(1)}p/hr` : '--'}
          </div>
          {currentPrice != null && (
            <div className="text-xs text-gray-500 mt-1">@ {currentPrice.toFixed(2)}p/kWh</div>
          )}
        </div>
      </div>

      {/* Projected costs */}
      <div className="border-t border-gray-700 pt-4">
        <h4 className="text-sm text-gray-400 mb-3">Projected Costs (at current rate)</h4>
        <div className="grid grid-cols-3 gap-3">
          {/* Hourly average */}
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Avg Hourly</div>
            <div className="text-sm font-medium text-gray-300">
              {avgHourlyCost !== null ? `${avgHourlyCost.toFixed(1)}p` : '--'}
            </div>
          </div>

          {/* Daily estimate */}
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Daily Est.</div>
            <div className="text-sm font-medium text-yellow-400">
              {dailyCostEstimate !== null ? formatCost(dailyCostEstimate) : '--'}
            </div>
          </div>

          {/* Monthly estimate */}
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Monthly Est.</div>
            <div className="text-sm font-medium text-orange-400">
              {dailyCostEstimate !== null ? formatCost(dailyCostEstimate * 30) : '--'}
            </div>
          </div>
        </div>
      </div>

      {/* Current price info */}
      {currentPrice != null && (
        <div className="mt-4 pt-4 border-t border-gray-700">
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2 text-gray-400">
              <Zap className="w-4 h-4" />
              <span>Current Agile Price</span>
            </div>
            <span
              className={`font-medium ${currentPrice < 0 ? 'text-green-400' : currentPrice < 15 ? 'text-blue-400' : currentPrice < 25 ? 'text-yellow-400' : 'text-red-400'}`}
            >
              {currentPrice.toFixed(2)}p/kWh
            </span>
          </div>
        </div>
      )}

      {/* No data state */}
      {!stats && !isLoading && (
        <div className="text-center text-gray-500 py-4">
          <p>Waiting for telemetry data...</p>
        </div>
      )}
    </div>
  );
}

export default LiveCostTracker;
