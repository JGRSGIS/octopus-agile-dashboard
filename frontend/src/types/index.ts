/**
 * TypeScript type definitions for the Octopus Agile Dashboard
 */

// Price data from API
export interface PricePeriod {
  valid_from: string;
  valid_to: string;
  value_exc_vat: number;
  value_inc_vat: number;
  payment_method?: string | null;
}

// Consumption data from API
export interface ConsumptionPeriod {
  interval_start: string;
  interval_end: string;
  consumption: number;
}

// Price statistics
export interface PriceStats {
  count: number;
  average: number;
  minimum: number;
  maximum: number;
  negative_count: number;
  total_negative_value: number;
  cheapest_periods: PricePeriod[];
  most_expensive_periods: PricePeriod[];
}

// Consumption statistics
export interface ConsumptionStats {
  total_kwh: number;
  period_count: number;
  average_per_period: number;
  peak_consumption: number;
  peak_period: ConsumptionPeriod | null;
  daily_breakdown: Record<string, number>;
}

// Cost analysis
export interface CostAnalysis {
  total_cost_pence: number;
  total_cost_pounds: number;
  total_kwh: number;
  weighted_average_price: number;
  savings_vs_flat_rate: number;
  cost_by_period: CostPeriod[];
  cheapest_hours: CostPeriod[];
  most_expensive_hours: CostPeriod[];
}

export interface CostPeriod {
  interval_start: string;
  interval_end: string;
  consumption_kwh: number;
  price_pence: number;
  cost_pence: number;
}

// API response types
export interface PricesResponse {
  region: string;
  product_code: string;
  tariff_code: string;
  count: number;
  prices: PricePeriod[];
  stats?: PriceStats;
}

export interface CurrentPriceResponse {
  region: string;
  product_code: string;
  timestamp: string;
  current: PricePeriod | null;
  upcoming: PricePeriod[];
  past_24h: PricePeriod[];
  best_upcoming: PricePeriod[];
  has_negative_upcoming: boolean;
}

export interface ConsumptionResponse {
  mpan: string;
  serial_number: string;
  count: number;
  consumption: ConsumptionPeriod[];
  stats?: ConsumptionStats;
}

export interface DashboardResponse {
  timestamp: string;
  region: string;
  current_price: PricePeriod | null;
  upcoming_prices: PricePeriod[];
  best_upcoming: PricePeriod[];
  has_negative_upcoming: boolean;
  prices_48h: PricePeriod[];
  consumption_7d: ConsumptionPeriod[];
  today: {
    prices: PriceStats;
    consumption: ConsumptionStats;
  };
  cost_analysis: CostAnalysis;
}

// Recommendation types
export interface Recommendation {
  priority: 'URGENT' | 'HIGH' | 'MEDIUM' | 'AVOID';
  message: string;
  periods: PricePeriod[];
  suggested_uses?: string[];
  suggestions?: string[];
}

export interface RecommendationsResponse {
  hours_analyzed: number;
  total_periods: number;
  cheapest_period: PricePeriod | null;
  most_expensive_period: PricePeriod | null;
  recommendations: Recommendation[];
}

// Summary types
export interface PeriodSummary {
  period: string;
  period_from: string;
  period_to: string;
  prices: PriceStats;
  consumption: ConsumptionStats;
  cost: CostAnalysis;
}

// Chart data types
export interface ChartDataPoint {
  timestamp: Date;
  price?: number;
  consumption?: number;
  cost?: number;
}

// Table row types for AG Grid
export interface PriceTableRow {
  id: string;
  validFrom: Date;
  validTo: Date;
  priceExcVat: number;
  priceIncVat: number;
  priceCategory: 'negative' | 'cheap' | 'normal' | 'expensive';
}

export interface ConsumptionTableRow {
  id: string;
  intervalStart: Date;
  intervalEnd: Date;
  consumption: number;
  price?: number;
  cost?: number;
}

// Filter types
export interface DateRangeFilter {
  from: Date | null;
  to: Date | null;
}

export type PeriodFilter = 'today' | 'yesterday' | 'week' | 'month' | 'custom';

// Color theme
export interface PriceColorTheme {
  negative: string;
  cheap: string;
  normal: string;
  expensive: string;
  veryExpensive: string;
}

// Utility type for API errors
export interface ApiError {
  detail: string;
  status_code?: number;
}

// Health check response
export interface HealthResponse {
  status: string;
  version: string;
  region: string;
  cache_enabled: boolean;
}
