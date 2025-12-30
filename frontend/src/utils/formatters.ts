/**
 * Utility functions for formatting values
 */

import { format, parseISO, isValid } from 'date-fns';
import type { PricePeriod, PriceColorTheme } from '../types';

// ============ Price Formatting ============

/**
 * Format price in pence with 2 decimal places
 */
export function formatPrice(pence: number): string {
  return `${pence.toFixed(2)}p`;
}

/**
 * Format price in pounds
 */
export function formatPricePounds(pence: number): string {
  return `£${(pence / 100).toFixed(2)}`;
}

/**
 * Get price category based on value
 */
export function getPriceCategory(
  priceIncVat: number
): 'negative' | 'cheap' | 'normal' | 'expensive' | 'veryExpensive' {
  if (priceIncVat < 0) return 'negative';
  if (priceIncVat < 10) return 'cheap';
  if (priceIncVat < 20) return 'normal';
  if (priceIncVat < 35) return 'expensive';
  return 'veryExpensive';
}

/**
 * Default price color theme
 */
export const priceColors: PriceColorTheme = {
  negative: '#10b981', // emerald-500
  cheap: '#3b82f6', // blue-500
  normal: '#eab308', // yellow-500
  expensive: '#f97316', // orange-500
  veryExpensive: '#ef4444', // red-500
};

/**
 * Get color for a price value
 */
export function getPriceColor(priceIncVat: number): string {
  const category = getPriceCategory(priceIncVat);
  return priceColors[category];
}

/**
 * Get background color class for price (Tailwind)
 */
export function getPriceBgClass(priceIncVat: number): string {
  const category = getPriceCategory(priceIncVat);
  const bgClasses = {
    negative: 'bg-emerald-500',
    cheap: 'bg-blue-500',
    normal: 'bg-yellow-500',
    expensive: 'bg-orange-500',
    veryExpensive: 'bg-red-500',
  };
  return bgClasses[category];
}

/**
 * Get text color class for price (Tailwind)
 */
export function getPriceTextClass(priceIncVat: number): string {
  const category = getPriceCategory(priceIncVat);
  const textClasses = {
    negative: 'text-emerald-500',
    cheap: 'text-blue-500',
    normal: 'text-yellow-500',
    expensive: 'text-orange-500',
    veryExpensive: 'text-red-500',
  };
  return textClasses[category];
}

// ============ Date/Time Formatting ============

/**
 * Parse ISO date string safely
 */
export function parseDate(dateString: string): Date {
  const parsed = parseISO(dateString);
  return isValid(parsed) ? parsed : new Date(dateString);
}

/**
 * Format date for display
 */
export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? parseDate(date) : date;
  return format(d, 'dd MMM yyyy');
}

/**
 * Format time for display (24-hour)
 */
export function formatTime(date: Date | string): string {
  const d = typeof date === 'string' ? parseDate(date) : date;
  return format(d, 'HH:mm');
}

/**
 * Format date and time
 */
export function formatDateTime(date: Date | string): string {
  const d = typeof date === 'string' ? parseDate(date) : date;
  return format(d, 'dd MMM HH:mm');
}

/**
 * Format a price period for display
 */
export function formatPeriod(period: PricePeriod): string {
  const from = parseDate(period.valid_from);
  const to = parseDate(period.valid_to);
  return `${formatTime(from)} - ${formatTime(to)}`;
}

/**
 * Format relative time (e.g., "2 hours ago")
 */
export function formatRelativeTime(date: Date | string): string {
  const d = typeof date === 'string' ? parseDate(date) : date;
  const now = new Date();
  const diffMs = now.getTime() - d.getTime();
  const diffMins = Math.floor(diffMs / (1000 * 60));

  if (diffMins < 0) {
    // Future
    const futureMins = Math.abs(diffMins);
    if (futureMins < 60) return `in ${futureMins} mins`;
    if (futureMins < 1440) return `in ${Math.floor(futureMins / 60)} hours`;
    return `in ${Math.floor(futureMins / 1440)} days`;
  }

  if (diffMins < 1) return 'just now';
  if (diffMins < 60) return `${diffMins} mins ago`;
  if (diffMins < 1440) return `${Math.floor(diffMins / 60)} hours ago`;
  return `${Math.floor(diffMins / 1440)} days ago`;
}

// ============ Consumption Formatting ============

/**
 * Format kWh value
 */
export function formatKwh(kwh: number): string {
  if (kwh < 1) {
    return `${(kwh * 1000).toFixed(0)} Wh`;
  }
  return `${kwh.toFixed(2)} kWh`;
}

/**
 * Format consumption for display
 */
export function formatConsumption(kwh: number): string {
  return `${kwh.toFixed(3)} kWh`;
}

// ============ Cost Formatting ============

/**
 * Format cost in pence
 */
export function formatCostPence(pence: number): string {
  if (pence < 100) {
    return `${pence.toFixed(1)}p`;
  }
  return formatPricePounds(pence);
}

/**
 * Format savings (can be positive or negative)
 */
export function formatSavings(pence: number): string {
  const prefix = pence >= 0 ? '+' : '';
  return `${prefix}${formatCostPence(pence)}`;
}

// ============ Number Formatting ============

/**
 * Format large numbers with K/M suffixes
 */
export function formatLargeNumber(num: number): string {
  if (num >= 1000000) {
    return `${(num / 1000000).toFixed(1)}M`;
  }
  if (num >= 1000) {
    return `${(num / 1000).toFixed(1)}K`;
  }
  return num.toFixed(0);
}

/**
 * Format percentage
 */
export function formatPercentage(value: number, decimals: number = 1): string {
  return `${value.toFixed(decimals)}%`;
}

// ============ Chart Data Helpers ============

/**
 * Prepare price data for Plotly chart
 */
export function preparePriceChartData(prices: PricePeriod[]) {
  return prices.map((p) => ({
    x: parseDate(p.valid_from),
    y: p.value_inc_vat,
    color: getPriceColor(p.value_inc_vat),
  }));
}

/**
 * Get price color array for bar chart
 */
export function getPriceColors(prices: PricePeriod[]): string[] {
  return prices.map((p) => getPriceColor(p.value_inc_vat));
}
