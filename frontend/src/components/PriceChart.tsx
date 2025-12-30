/**
 * Interactive price chart using Plotly
 */

import { useMemo } from 'react';
import Plot from 'react-plotly.js';
import type { PricePeriod, ConsumptionPeriod } from '../types';
import { parseDate, getPriceColor } from '../utils/formatters';

interface PriceChartProps {
  prices: PricePeriod[];
  consumption?: ConsumptionPeriod[];
  title?: string;
  height?: number;
  showConsumption?: boolean;
}

export function PriceChart({
  prices,
  consumption = [],
  title = 'Agile Prices',
  height = 400,
  showConsumption = true,
}: PriceChartProps) {
  // Prepare price data
  const priceData = useMemo(() => {
    return prices.map((p) => ({
      x: parseDate(p.valid_from),
      y: p.value_inc_vat,
      color: getPriceColor(p.value_inc_vat),
    }));
  }, [prices]);

  // Prepare consumption data
  const consumptionData = useMemo(() => {
    return consumption.map((c) => ({
      x: parseDate(c.interval_start),
      y: c.consumption,
    }));
  }, [consumption]);

  // Get colors array for bar chart
  const colors = useMemo(() => {
    return prices.map((p) => getPriceColor(p.value_inc_vat));
  }, [prices]);

  // Find current time for vertical line (as ISO string for Plotly)
  const now = new Date().toISOString();

  // Create traces
  const traces: Plotly.Data[] = [
    {
      name: 'Price (p/kWh)',
      x: priceData.map((d) => d.x),
      y: priceData.map((d) => d.y),
      type: 'bar',
      marker: {
        color: colors,
      },
      hovertemplate: '%{y:.2f}p/kWh<br>%{x}<extra></extra>',
    },
  ];

  // Add consumption trace if available
  if (showConsumption && consumptionData.length > 0) {
    traces.push({
      name: 'Usage (kWh)',
      x: consumptionData.map((d) => d.x),
      y: consumptionData.map((d) => d.y),
      type: 'scatter',
      mode: 'lines+markers',
      yaxis: 'y2',
      line: {
        color: '#8b5cf6',
        width: 2,
      },
      marker: {
        size: 4,
        color: '#8b5cf6',
      },
      hovertemplate: '%{y:.3f} kWh<br>%{x}<extra></extra>',
    });
  }

  // Layout configuration
  const layout: Partial<Plotly.Layout> = {
    title: {
      text: title,
      font: {
        color: '#e5e7eb',
        size: 16,
      },
    },
    paper_bgcolor: 'transparent',
    plot_bgcolor: 'transparent',
    height,
    margin: {
      l: 60,
      r: showConsumption && consumptionData.length > 0 ? 60 : 20,
      t: 50,
      b: 60,
    },
    xaxis: {
      title: {
        text: '',
      },
      tickformat: '%H:%M',
      tickangle: -45,
      gridcolor: '#374151',
      tickfont: { color: '#9ca3af' },
      showgrid: true,
      zeroline: false,
    },
    yaxis: {
      title: {
        text: 'Price (p/kWh)',
        font: { color: '#9ca3af' },
      },
      tickfont: { color: '#9ca3af' },
      gridcolor: '#374151',
      zeroline: true,
      zerolinecolor: '#6b7280',
      zerolinewidth: 2,
    },
    yaxis2: showConsumption && consumptionData.length > 0 ? {
      title: {
        text: 'Usage (kWh)',
        font: { color: '#8b5cf6' },
      },
      tickfont: { color: '#8b5cf6' },
      overlaying: 'y',
      side: 'right',
      showgrid: false,
    } : undefined,
    legend: {
      orientation: 'h',
      x: 0.5,
      xanchor: 'center',
      y: 1.1,
      font: { color: '#9ca3af' },
    },
    shapes: [
      // Current time vertical line
      {
        type: 'line',
        x0: now,
        x1: now,
        y0: 0,
        y1: 1,
        yref: 'paper',
        line: {
          color: '#ef4444',
          width: 2,
          dash: 'dot',
        },
      },
    ],
    annotations: [
      {
        x: now,
        y: 1.02,
        yref: 'paper',
        text: 'Now',
        showarrow: false,
        font: { color: '#ef4444', size: 10 },
      },
    ],
    hovermode: 'x unified',
    dragmode: 'zoom',
  };

  // Config
  const config: Partial<Plotly.Config> = {
    displayModeBar: true,
    modeBarButtonsToRemove: ['lasso2d', 'select2d'],
    displaylogo: false,
    responsive: true,
  };

  return (
    <div className="bg-gray-800 rounded-xl p-4">
      <Plot
        data={traces}
        layout={layout}
        config={config}
        style={{ width: '100%', height: '100%' }}
        useResizeHandler={true}
      />
    </div>
  );
}

export default PriceChart;
