/**
 * Agile vs Fixed Tariff Comparison Component
 * Compares Octopus Agile costs against Octopus 12M Fixed September 2025 v1
 */

import { TrendingDown, TrendingUp, Zap, Calendar, PoundSterling } from 'lucide-react';
import createPlotlyComponent from 'react-plotly.js/factory';
import type { CostAnalysis } from '../types';

// Use the global Plotly object loaded from CDN
const Plot = createPlotlyComponent(window.Plotly);

interface AgileComparisonProps {
  costAnalysis: CostAnalysis;
}

interface ComparisonCardProps {
  title: string;
  value: string;
  subtitle: string;
  icon: React.ReactNode;
  colorClass: string;
  highlight?: boolean;
}

function ComparisonCard({ title, value, subtitle, icon, colorClass, highlight }: ComparisonCardProps) {
  return (
    <div
      className={`bg-gray-800 rounded-xl p-5 ${highlight ? 'ring-2 ring-offset-2 ring-offset-gray-900' : ''} ${
        highlight ? (colorClass.includes('emerald') ? 'ring-emerald-500' : 'ring-red-500') : ''
      }`}
    >
      <div className="flex items-start justify-between">
        <div>
          <p className="text-gray-400 text-sm">{title}</p>
          <p className={`text-3xl font-bold mt-1 ${colorClass}`}>{value}</p>
          <p className="text-gray-500 text-xs mt-1">{subtitle}</p>
        </div>
        <div className={`${colorClass} opacity-50`}>{icon}</div>
      </div>
    </div>
  );
}

function formatPounds(pence: number): string {
  return `£${(pence / 100).toFixed(2)}`;
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('en-GB', { weekday: 'short', day: 'numeric', month: 'short' });
}

export function AgileComparison({ costAnalysis }: AgileComparisonProps) {
  const {
    fixed_total_cost_pence,
    agile_total_cost_pence,
    agile_savings_pence,
    days_in_period,
    total_kwh,
    fixed_tariff_unit_rate,
    fixed_tariff_standing_charge,
    agile_standing_charge,
    weighted_average_price,
    daily_comparison,
  } = costAnalysis;

  const isSaving = agile_savings_pence > 0;
  const savingsPercent = fixed_total_cost_pence > 0
    ? ((agile_savings_pence / fixed_total_cost_pence) * 100).toFixed(1)
    : '0';

  const daysAgileCheaper = daily_comparison.filter(d => d.agile_cheaper).length;
  const daysFixedCheaper = days_in_period - daysAgileCheaper;

  // Prepare chart data
  const chartData = {
    dates: daily_comparison.map(d => formatDate(d.date)),
    fixedCosts: daily_comparison.map(d => d.fixed_cost_pence / 100),
    agileCosts: daily_comparison.map(d => d.agile_cost_pence / 100),
    savings: daily_comparison.map(d => d.savings_pence / 100),
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-gray-800 rounded-xl p-6">
        <div className="flex items-center gap-3 mb-2">
          <Zap className="w-6 h-6 text-yellow-400" />
          <h2 className="text-xl font-bold">Agile vs Fixed Tariff Comparison</h2>
        </div>
        <p className="text-gray-400 text-sm">
          Comparing your actual Agile costs against what you would pay on{' '}
          <span className="text-blue-400 font-medium">Octopus 12M Fixed September 2025 v1</span>
        </p>
        <div className="mt-3 flex flex-wrap gap-4 text-xs text-gray-500">
          <span>Fixed: {fixed_tariff_unit_rate}p/kWh + {fixed_tariff_standing_charge}p/day</span>
          <span>Agile: Variable + {agile_standing_charge}p/day</span>
          <span>Period: {days_in_period} days</span>
          <span>Usage: {total_kwh.toFixed(1)} kWh</span>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <ComparisonCard
          title="Fixed Tariff Cost"
          value={formatPounds(fixed_total_cost_pence)}
          subtitle={`${days_in_period} days @ ${fixed_tariff_unit_rate}p/kWh`}
          icon={<PoundSterling className="w-6 h-6" />}
          colorClass="text-blue-400"
        />
        <ComparisonCard
          title="Agile Cost"
          value={formatPounds(agile_total_cost_pence)}
          subtitle={`Avg ${weighted_average_price.toFixed(1)}p/kWh`}
          icon={<Zap className="w-6 h-6" />}
          colorClass="text-yellow-400"
        />
        <ComparisonCard
          title={isSaving ? 'You Saved' : 'Extra Cost'}
          value={formatPounds(Math.abs(agile_savings_pence))}
          subtitle={`${Math.abs(Number(savingsPercent))}% ${isSaving ? 'cheaper' : 'more expensive'}`}
          icon={isSaving ? <TrendingDown className="w-6 h-6" /> : <TrendingUp className="w-6 h-6" />}
          colorClass={isSaving ? 'text-emerald-400' : 'text-red-400'}
          highlight={true}
        />
        <ComparisonCard
          title="Agile Won"
          value={`${daysAgileCheaper}/${days_in_period}`}
          subtitle={`${daysFixedCheaper} days Fixed was cheaper`}
          icon={<Calendar className="w-6 h-6" />}
          colorClass={daysAgileCheaper > daysFixedCheaper ? 'text-emerald-400' : 'text-orange-400'}
        />
      </div>

      {/* Verdict Banner */}
      <div
        className={`rounded-xl p-6 ${
          isSaving
            ? 'bg-emerald-900/30 border border-emerald-500/50'
            : 'bg-red-900/30 border border-red-500/50'
        }`}
      >
        <div className="flex items-center gap-4">
          <div
            className={`rounded-full p-3 ${isSaving ? 'bg-emerald-500/20' : 'bg-red-500/20'}`}
          >
            {isSaving ? (
              <TrendingDown className={`w-8 h-8 text-emerald-400`} />
            ) : (
              <TrendingUp className={`w-8 h-8 text-red-400`} />
            )}
          </div>
          <div>
            <h3 className={`font-bold text-lg ${isSaving ? 'text-emerald-400' : 'text-red-400'}`}>
              {isSaving
                ? `Agile saved you ${formatPounds(agile_savings_pence)} over ${days_in_period} days!`
                : `Agile cost you ${formatPounds(Math.abs(agile_savings_pence))} more over ${days_in_period} days`}
            </h3>
            <p className="text-gray-300">
              {isSaving
                ? `That's ${savingsPercent}% less than what you would have paid on the Fixed tariff. Your smart usage patterns are paying off!`
                : `That's ${Math.abs(Number(savingsPercent))}% more than the Fixed tariff. Consider shifting usage to cheaper periods.`}
            </p>
          </div>
        </div>
      </div>

      {/* Daily Comparison Chart */}
      <div className="bg-gray-800 rounded-xl p-4">
        <h3 className="text-lg font-semibold mb-4">Daily Cost Comparison</h3>
        <Plot
          data={[
            {
              x: chartData.dates,
              y: chartData.fixedCosts,
              type: 'bar',
              name: 'Fixed Tariff',
              marker: { color: '#3b82f6' },
              hovertemplate: '%{x}<br>Fixed: £%{y:.2f}<extra></extra>',
            },
            {
              x: chartData.dates,
              y: chartData.agileCosts,
              type: 'bar',
              name: 'Agile',
              marker: {
                color: daily_comparison.map(d =>
                  d.agile_cheaper ? '#10b981' : '#ef4444'
                ),
              },
              hovertemplate: '%{x}<br>Agile: £%{y:.2f}<extra></extra>',
            },
          ]}
          layout={{
            autosize: true,
            height: 350,
            margin: { l: 50, r: 20, t: 20, b: 60 },
            paper_bgcolor: 'transparent',
            plot_bgcolor: 'transparent',
            font: { color: '#9ca3af' },
            barmode: 'group',
            xaxis: {
              gridcolor: '#374151',
              tickangle: -45,
            },
            yaxis: {
              gridcolor: '#374151',
              title: { text: 'Cost (£)' },
              tickprefix: '£',
            },
            legend: {
              orientation: 'h',
              y: -0.2,
              x: 0.5,
              xanchor: 'center',
            },
            showlegend: true,
          }}
          config={{
            displayModeBar: false,
            responsive: true,
          }}
          style={{ width: '100%' }}
        />
        <p className="text-xs text-gray-500 mt-2 text-center">
          Green bars = Agile cheaper | Red bars = Fixed cheaper
        </p>
      </div>

      {/* Savings Chart */}
      <div className="bg-gray-800 rounded-xl p-4">
        <h3 className="text-lg font-semibold mb-4">Daily Savings (Fixed - Agile)</h3>
        <Plot
          data={[
            {
              x: chartData.dates,
              y: chartData.savings,
              type: 'bar',
              marker: {
                color: chartData.savings.map(s => (s >= 0 ? '#10b981' : '#ef4444')),
              },
              hovertemplate: '%{x}<br>Savings: £%{y:.2f}<extra></extra>',
            },
          ]}
          layout={{
            autosize: true,
            height: 250,
            margin: { l: 50, r: 20, t: 20, b: 60 },
            paper_bgcolor: 'transparent',
            plot_bgcolor: 'transparent',
            font: { color: '#9ca3af' },
            xaxis: {
              gridcolor: '#374151',
              tickangle: -45,
            },
            yaxis: {
              gridcolor: '#374151',
              title: { text: 'Savings (£)' },
              tickprefix: '£',
              zeroline: true,
              zerolinecolor: '#6b7280',
              zerolinewidth: 2,
            },
            showlegend: false,
          }}
          config={{
            displayModeBar: false,
            responsive: true,
          }}
          style={{ width: '100%' }}
        />
        <p className="text-xs text-gray-500 mt-2 text-center">
          Positive = Agile saved money | Negative = Fixed would have been cheaper
        </p>
      </div>

      {/* Daily Breakdown Table */}
      <div className="bg-gray-800 rounded-xl p-4">
        <h3 className="text-lg font-semibold mb-4">Daily Breakdown</h3>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-gray-700">
                <th className="text-left py-3 px-4 text-gray-400 font-medium">Date</th>
                <th className="text-right py-3 px-4 text-gray-400 font-medium">Usage</th>
                <th className="text-right py-3 px-4 text-gray-400 font-medium">Fixed Cost</th>
                <th className="text-right py-3 px-4 text-gray-400 font-medium">Agile Cost</th>
                <th className="text-right py-3 px-4 text-gray-400 font-medium">Difference</th>
                <th className="text-center py-3 px-4 text-gray-400 font-medium">Winner</th>
              </tr>
            </thead>
            <tbody>
              {daily_comparison.map((day, index) => (
                <tr
                  key={day.date}
                  className={`border-b border-gray-700/50 ${
                    index % 2 === 0 ? 'bg-gray-800/50' : ''
                  }`}
                >
                  <td className="py-3 px-4 font-medium">{formatDate(day.date)}</td>
                  <td className="py-3 px-4 text-right text-gray-300">{day.kwh.toFixed(2)} kWh</td>
                  <td className="py-3 px-4 text-right text-blue-400">
                    {formatPounds(day.fixed_cost_pence)}
                  </td>
                  <td className="py-3 px-4 text-right text-yellow-400">
                    {formatPounds(day.agile_cost_pence)}
                  </td>
                  <td
                    className={`py-3 px-4 text-right font-medium ${
                      day.agile_cheaper ? 'text-emerald-400' : 'text-red-400'
                    }`}
                  >
                    {day.agile_cheaper ? '-' : '+'}
                    {formatPounds(Math.abs(day.savings_pence))}
                  </td>
                  <td className="py-3 px-4 text-center">
                    {day.agile_cheaper ? (
                      <span className="inline-flex items-center gap-1 text-emerald-400">
                        <Zap className="w-4 h-4" /> Agile
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 text-blue-400">
                        <PoundSterling className="w-4 h-4" /> Fixed
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-gray-600 font-bold">
                <td className="py-3 px-4">Total</td>
                <td className="py-3 px-4 text-right text-gray-300">{total_kwh.toFixed(2)} kWh</td>
                <td className="py-3 px-4 text-right text-blue-400">
                  {formatPounds(fixed_total_cost_pence)}
                </td>
                <td className="py-3 px-4 text-right text-yellow-400">
                  {formatPounds(agile_total_cost_pence)}
                </td>
                <td
                  className={`py-3 px-4 text-right ${
                    isSaving ? 'text-emerald-400' : 'text-red-400'
                  }`}
                >
                  {isSaving ? '-' : '+'}
                  {formatPounds(Math.abs(agile_savings_pence))}
                </td>
                <td className="py-3 px-4 text-center">
                  {isSaving ? (
                    <span className="inline-flex items-center gap-1 text-emerald-400">
                      <Zap className="w-4 h-4" /> Agile
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 text-blue-400">
                      <PoundSterling className="w-4 h-4" /> Fixed
                    </span>
                  )}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      {/* Info Footer */}
      <div className="bg-gray-800/50 rounded-xl p-4 text-sm text-gray-400">
        <p className="mb-2">
          <strong className="text-gray-300">Note:</strong> This comparison includes both unit rates and standing charges.
        </p>
        <ul className="list-disc list-inside space-y-1 text-xs">
          <li>Fixed tariff: {fixed_tariff_unit_rate}p/kWh unit rate + {fixed_tariff_standing_charge}p/day standing charge</li>
          <li>Agile tariff: Variable half-hourly rates + {agile_standing_charge}p/day standing charge</li>
          <li>Data based on your actual consumption over the last {days_in_period} days</li>
        </ul>
      </div>
    </div>
  );
}

export default AgileComparison;
