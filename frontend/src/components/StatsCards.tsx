/**
 * Statistics cards display component
 */

import { TrendingUp, TrendingDown, Activity, Zap, PiggyBank, Clock } from 'lucide-react';
import type { PriceStats, ConsumptionStats, CostAnalysis } from '../types';
import {
  formatPrice,
  formatKwh,
  formatCostPence,
  formatSavings,
  getPriceTextClass,
} from '../utils/formatters';

interface StatsCardsProps {
  priceStats?: PriceStats | null;
  consumptionStats?: ConsumptionStats | null;
  costAnalysis?: CostAnalysis | null;
  onPeriodClick?: (period: 'today' | 'week' | 'month') => void;
  selectedPeriod?: string;
}

interface StatCardProps {
  title: string;
  value: string;
  subtitle?: string;
  icon: React.ReactNode;
  colorClass?: string;
  onClick?: () => void;
  isActive?: boolean;
}

function StatCard({
  title,
  value,
  subtitle,
  icon,
  colorClass = 'text-blue-400',
  onClick,
  isActive,
}: StatCardProps) {
  return (
    <div
      className={`bg-gray-800 rounded-xl p-4 transition-all ${
        onClick ? 'cursor-pointer hover:bg-gray-700 hover:scale-105' : ''
      } ${isActive ? 'ring-2 ring-blue-500' : ''}`}
      onClick={onClick}
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-gray-400 text-sm">{title}</p>
          <p className={`text-2xl font-bold mt-1 ${colorClass}`}>{value}</p>
          {subtitle && <p className="text-gray-500 text-xs mt-1">{subtitle}</p>}
        </div>
        <div className={`${colorClass} opacity-50`}>{icon}</div>
      </div>
    </div>
  );
}

export function StatsCards({
  priceStats,
  consumptionStats,
  costAnalysis,
  onPeriodClick,
  selectedPeriod,
}: StatsCardsProps) {
  return (
    <div className="space-y-6">
      {/* Period Selector */}
      {onPeriodClick && (
        <div className="flex gap-2">
          {['today', 'week', 'month'].map((period) => (
            <button
              key={period}
              onClick={() => onPeriodClick(period as 'today' | 'week' | 'month')}
              className={`px-4 py-2 rounded-lg font-medium transition-all ${
                selectedPeriod === period
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
              }`}
            >
              {period === 'today' ? 'Today' : period === 'week' ? 'This Week' : 'This Month'}
            </button>
          ))}
        </div>
      )}

      {/* Price Stats */}
      {priceStats && (
        <div>
          <h3 className="text-gray-400 text-sm font-medium mb-3 uppercase tracking-wide">
            Price Statistics
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatCard
              title="Average"
              value={formatPrice(priceStats.average)}
              icon={<Activity className="w-5 h-5" />}
              colorClass="text-blue-400"
            />
            <StatCard
              title="Minimum"
              value={formatPrice(priceStats.minimum)}
              icon={<TrendingDown className="w-5 h-5" />}
              colorClass={getPriceTextClass(priceStats.minimum)}
            />
            <StatCard
              title="Maximum"
              value={formatPrice(priceStats.maximum)}
              icon={<TrendingUp className="w-5 h-5" />}
              colorClass={getPriceTextClass(priceStats.maximum)}
            />
            <StatCard
              title="Negative Periods"
              value={priceStats.negative_count.toString()}
              subtitle={priceStats.negative_count > 0 ? 'Free power!' : 'None today'}
              icon={<Zap className="w-5 h-5" />}
              colorClass={priceStats.negative_count > 0 ? 'text-emerald-400' : 'text-gray-400'}
            />
          </div>
        </div>
      )}

      {/* Consumption Stats */}
      {consumptionStats && (
        <div>
          <h3 className="text-gray-400 text-sm font-medium mb-3 uppercase tracking-wide">
            Consumption
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatCard
              title="Total Usage"
              value={formatKwh(consumptionStats.total_kwh)}
              icon={<Activity className="w-5 h-5" />}
              colorClass="text-purple-400"
            />
            <StatCard
              title="Periods"
              value={consumptionStats.period_count.toString()}
              subtitle="half-hour slots"
              icon={<Clock className="w-5 h-5" />}
              colorClass="text-gray-300"
            />
            <StatCard
              title="Avg/Period"
              value={formatKwh(consumptionStats.average_per_period)}
              icon={<Activity className="w-5 h-5" />}
              colorClass="text-purple-400"
            />
            <StatCard
              title="Peak Usage"
              value={formatKwh(consumptionStats.peak_consumption)}
              icon={<TrendingUp className="w-5 h-5" />}
              colorClass="text-orange-400"
            />
          </div>
        </div>
      )}

      {/* Cost Analysis */}
      {costAnalysis && (
        <div>
          <h3 className="text-gray-400 text-sm font-medium mb-3 uppercase tracking-wide">
            Cost Analysis
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <StatCard
              title="Total Cost"
              value={formatCostPence(costAnalysis.total_cost_pence)}
              subtitle={`${formatKwh(costAnalysis.total_kwh)} used`}
              icon={<PiggyBank className="w-5 h-5" />}
              colorClass="text-yellow-400"
            />
            <StatCard
              title="Avg Price Paid"
              value={formatPrice(costAnalysis.weighted_average_price)}
              subtitle="weighted by usage"
              icon={<Activity className="w-5 h-5" />}
              colorClass="text-blue-400"
            />
            <StatCard
              title="vs Flat Rate"
              value={formatSavings(costAnalysis.savings_vs_flat_rate)}
              subtitle="compared to 24.5p/kWh"
              icon={
                costAnalysis.savings_vs_flat_rate >= 0 ? (
                  <TrendingDown className="w-5 h-5" />
                ) : (
                  <TrendingUp className="w-5 h-5" />
                )
              }
              colorClass={
                costAnalysis.savings_vs_flat_rate >= 0 ? 'text-emerald-400' : 'text-red-400'
              }
            />
            <StatCard
              title="Matched Periods"
              value={costAnalysis.cost_by_period.length.toString()}
              subtitle="price × usage"
              icon={<Clock className="w-5 h-5" />}
              colorClass="text-gray-300"
            />
          </div>
        </div>
      )}
    </div>
  );
}

export default StatsCards;
