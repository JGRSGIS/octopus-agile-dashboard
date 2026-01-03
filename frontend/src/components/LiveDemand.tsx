/**
 * LiveDemand component - displays current electricity demand from Home Mini
 */

import { Activity, Zap, TrendingUp, TrendingDown, Minus } from 'lucide-react';
import type { LatestReadingResponse, TelemetrySummary } from '../types';
import { formatRelativeTime } from '../utils/formatters';

interface LiveDemandProps {
  current: LatestReadingResponse | null;
  stats: TelemetrySummary | null;
  isLoading?: boolean;
}

// Get color based on demand level (in watts)
function getDemandColor(watts: number | null): string {
  if (watts === null) return 'text-gray-400';
  if (watts < 500) return 'text-green-400'; // Low usage
  if (watts < 1000) return 'text-blue-400'; // Normal
  if (watts < 2000) return 'text-yellow-400'; // Moderate
  if (watts < 3000) return 'text-orange-400'; // High
  return 'text-red-400'; // Very high
}

function getDemandBgColor(watts: number | null): string {
  if (watts === null) return 'bg-gray-800';
  if (watts < 500) return 'bg-green-900/30';
  if (watts < 1000) return 'bg-blue-900/30';
  if (watts < 2000) return 'bg-yellow-900/30';
  if (watts < 3000) return 'bg-orange-900/30';
  return 'bg-red-900/30';
}

function getDemandLabel(watts: number | null): string {
  if (watts === null) return 'Unknown';
  if (watts < 500) return 'Low';
  if (watts < 1000) return 'Normal';
  if (watts < 2000) return 'Moderate';
  if (watts < 3000) return 'High';
  return 'Very High';
}

// Format watts for display
function formatWatts(watts: number | null): string {
  if (watts === null) return '--';
  if (watts >= 1000) {
    return `${(watts / 1000).toFixed(2)} kW`;
  }
  return `${Math.round(watts)} W`;
}

export function LiveDemand({ current, stats, isLoading }: LiveDemandProps) {
  const demandWatts = current?.current_demand_watts ?? null;
  const demandKw = current?.current_demand_kw ?? null;

  // Calculate trend from stats
  const avgDemand = stats?.demand?.average_kw;
  const trend =
    demandKw !== null && avgDemand !== undefined
      ? demandKw > avgDemand * 1.1
        ? 'up'
        : demandKw < avgDemand * 0.9
          ? 'down'
          : 'stable'
      : null;

  return (
    <div
      className={`rounded-2xl p-6 ${getDemandBgColor(demandWatts)} border border-gray-700 transition-colors duration-500`}
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <Activity className="w-5 h-5 text-blue-400" />
          <h3 className="text-lg font-semibold text-gray-200">Live Demand</h3>
        </div>
        <div className="flex items-center gap-1">
          <div
            className={`w-2 h-2 rounded-full ${isLoading ? 'bg-yellow-400 animate-pulse' : 'bg-green-400 animate-pulse'}`}
          />
          <span className="text-xs text-gray-400">{isLoading ? 'Updating...' : 'Live'}</span>
        </div>
      </div>

      {/* Main demand display */}
      <div className="text-center py-6">
        <div className={`text-5xl font-bold ${getDemandColor(demandWatts)} mb-2`}>
          {formatWatts(demandWatts)}
        </div>
        <div className="flex items-center justify-center gap-2 text-gray-400">
          <Zap className="w-4 h-4" />
          <span className="text-sm">{getDemandLabel(demandWatts)} Usage</span>
          {trend === 'up' && <TrendingUp className="w-4 h-4 text-orange-400" />}
          {trend === 'down' && <TrendingDown className="w-4 h-4 text-green-400" />}
          {trend === 'stable' && <Minus className="w-4 h-4 text-gray-400" />}
        </div>
      </div>

      {/* Stats row */}
      {stats?.demand && (
        <div className="grid grid-cols-3 gap-4 pt-4 border-t border-gray-700">
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Average</div>
            <div className="text-sm font-medium text-gray-300">
              {stats.demand.average_kw !== undefined
                ? `${(stats.demand.average_kw * 1000).toFixed(0)} W`
                : '--'}
            </div>
          </div>
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Peak</div>
            <div className="text-sm font-medium text-orange-400">
              {stats.demand.peak_kw !== undefined
                ? `${(stats.demand.peak_kw * 1000).toFixed(0)} W`
                : '--'}
            </div>
          </div>
          <div className="text-center">
            <div className="text-xs text-gray-500 mb-1">Min</div>
            <div className="text-sm font-medium text-green-400">
              {stats.demand.min_kw !== undefined
                ? `${(stats.demand.min_kw * 1000).toFixed(0)} W`
                : '--'}
            </div>
          </div>
        </div>
      )}

      {/* Last updated */}
      {current?.reading?.read_at && (
        <div className="text-center mt-4 text-xs text-gray-500">
          Last reading: {formatRelativeTime(new Date(current.reading.read_at))}
        </div>
      )}
    </div>
  );
}

export default LiveDemand;
