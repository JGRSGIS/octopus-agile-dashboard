/**
 * LiveConsumptionChart - Rolling real-time consumption chart
 * Shows the last 5 minutes of 10-second telemetry data
 */

import { useEffect, useRef } from 'react';
import { BarChart3 } from 'lucide-react';
import type { TelemetryReading } from '../types';

// Declare Plotly on window
declare global {
  interface Window {
    Plotly: {
      newPlot: (
        element: HTMLElement,
        data: object[],
        layout: object,
        config: object
      ) => Promise<void>;
      react: (
        element: HTMLElement,
        data: object[],
        layout: object,
        config: object
      ) => Promise<void>;
    };
  }
}

interface LiveConsumptionChartProps {
  readings: TelemetryReading[];
  height?: number;
  isLoading?: boolean;
}

// Format time for display
function formatTime(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleTimeString('en-GB', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

export function LiveConsumptionChart({
  readings,
  height = 300,
  isLoading,
}: LiveConsumptionChartProps) {
  const chartRef = useRef<HTMLDivElement>(null);
  const isInitialized = useRef(false);

  useEffect(() => {
    if (!chartRef.current || !window.Plotly || readings.length === 0) return;

    // Prepare data for plotting
    const times = readings.map((r) => formatTime(r.read_at));
    const demands = readings.map((r) => (r.demand !== null ? r.demand * 1000 : 0)); // Convert to watts

    // Color based on demand level
    const colors = demands.map((d) => {
      if (d < 500) return 'rgba(34, 197, 94, 0.8)'; // green
      if (d < 1000) return 'rgba(59, 130, 246, 0.8)'; // blue
      if (d < 2000) return 'rgba(234, 179, 8, 0.8)'; // yellow
      if (d < 3000) return 'rgba(249, 115, 22, 0.8)'; // orange
      return 'rgba(239, 68, 68, 0.8)'; // red
    });

    const data = [
      {
        x: times,
        y: demands,
        type: 'bar',
        marker: {
          color: colors,
          line: {
            color: colors.map((c) => c.replace('0.8', '1')),
            width: 1,
          },
        },
        hovertemplate: '<b>%{x}</b><br>Demand: %{y:.0f} W<extra></extra>',
      },
    ];

    const layout = {
      title: {
        text: 'Real-Time Power Demand (Last 5 Minutes)',
        font: { color: '#e5e7eb', size: 14 },
        x: 0.02,
        xanchor: 'left',
      },
      paper_bgcolor: 'transparent',
      plot_bgcolor: 'transparent',
      margin: { l: 50, r: 20, t: 40, b: 60 },
      height: height,
      xaxis: {
        title: { text: 'Time', font: { color: '#9ca3af' } },
        tickfont: { color: '#9ca3af', size: 10 },
        gridcolor: 'rgba(75, 85, 99, 0.3)',
        tickangle: -45,
        nticks: 12,
      },
      yaxis: {
        title: { text: 'Power (Watts)', font: { color: '#9ca3af' } },
        tickfont: { color: '#9ca3af' },
        gridcolor: 'rgba(75, 85, 99, 0.3)',
        zeroline: true,
        zerolinecolor: 'rgba(75, 85, 99, 0.5)',
      },
      showlegend: false,
      hovermode: 'x unified',
    };

    const config = {
      responsive: true,
      displayModeBar: false,
    };

    if (!isInitialized.current) {
      window.Plotly.newPlot(chartRef.current, data, layout, config);
      isInitialized.current = true;
    } else {
      window.Plotly.react(chartRef.current, data, layout, config);
    }
  }, [readings, height]);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      isInitialized.current = false;
    };
  }, []);

  if (readings.length === 0 && !isLoading) {
    return (
      <div className="bg-gray-800/50 rounded-xl border border-gray-700 p-6">
        <div className="flex items-center gap-2 mb-4">
          <BarChart3 className="w-5 h-5 text-blue-400" />
          <h3 className="text-lg font-semibold text-gray-200">Real-Time Power Demand</h3>
        </div>
        <div className="flex items-center justify-center h-[200px] text-gray-500">
          <p>No telemetry data available</p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-800/50 rounded-xl border border-gray-700 p-4">
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <BarChart3 className="w-5 h-5 text-blue-400" />
          <span className="text-sm text-gray-400">
            {readings.length} readings over last 5 minutes
          </span>
        </div>
        {isLoading && (
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 rounded-full bg-blue-400 animate-pulse" />
            <span className="text-xs text-gray-500">Updating...</span>
          </div>
        )}
      </div>
      <div ref={chartRef} style={{ width: '100%', height: height }} />
    </div>
  );
}

export default LiveConsumptionChart;
