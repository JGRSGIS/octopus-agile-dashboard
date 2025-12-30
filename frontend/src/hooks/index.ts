/**
 * Custom React hooks for data fetching with React Query
 */

import type { UseQueryResult } from '@tanstack/react-query';
import { useQuery } from '@tanstack/react-query';
import { pricesApi, consumptionApi, analysisApi, healthApi } from '../services/api';
import type {
  PricesResponse,
  CurrentPriceResponse,
  ConsumptionResponse,
  DashboardResponse,
  RecommendationsResponse,
  PeriodSummary,
  HealthResponse,
  PriceStats,
} from '../types';

// Query key factory
export const queryKeys = {
  prices: {
    all: ['prices'] as const,
    current: () => [...queryKeys.prices.all, 'current'] as const,
    range: (from?: Date, to?: Date) => [...queryKeys.prices.all, 'range', from, to] as const,
    stats: (from?: Date, to?: Date) => [...queryKeys.prices.all, 'stats', from, to] as const,
    negative: (days: number) => [...queryKeys.prices.all, 'negative', days] as const,
  },
  consumption: {
    all: ['consumption'] as const,
    today: () => [...queryKeys.consumption.all, 'today'] as const,
    range: (from?: Date, to?: Date) => [...queryKeys.consumption.all, 'range', from, to] as const,
    daily: (days: number) => [...queryKeys.consumption.all, 'daily', days] as const,
  },
  analysis: {
    all: ['analysis'] as const,
    dashboard: () => [...queryKeys.analysis.all, 'dashboard'] as const,
    summary: (period: string) => [...queryKeys.analysis.all, 'summary', period] as const,
    recommendations: (hours: number) =>
      [...queryKeys.analysis.all, 'recommendations', hours] as const,
  },
  health: ['health'] as const,
};

// ============ Price Hooks ============

/**
 * Fetch current price and upcoming periods
 */
export function useCurrentPrice(): UseQueryResult<CurrentPriceResponse, Error> {
  return useQuery({
    queryKey: queryKeys.prices.current(),
    queryFn: () => pricesApi.getCurrentPrice(),
    refetchInterval: 5 * 60 * 1000, // Refetch every 5 minutes
    staleTime: 60 * 1000, // Consider stale after 1 minute
  });
}

/**
 * Fetch prices for a date range
 */
export function usePrices(
  periodFrom?: Date,
  periodTo?: Date
): UseQueryResult<PricesResponse, Error> {
  return useQuery({
    queryKey: queryKeys.prices.range(periodFrom, periodTo),
    queryFn: () => pricesApi.getPrices(periodFrom, periodTo),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

/**
 * Fetch price statistics
 */
export function usePriceStats(
  periodFrom?: Date,
  periodTo?: Date
): UseQueryResult<PriceStats, Error> {
  return useQuery({
    queryKey: queryKeys.prices.stats(periodFrom, periodTo),
    queryFn: () => pricesApi.getStats(periodFrom, periodTo),
    staleTime: 5 * 60 * 1000,
  });
}

/**
 * Fetch negative price periods
 */
export function useNegativePrices(days: number = 7) {
  return useQuery({
    queryKey: queryKeys.prices.negative(days),
    queryFn: () => pricesApi.getNegativePrices(days),
    staleTime: 30 * 60 * 1000, // 30 minutes
  });
}

// ============ Consumption Hooks ============

/**
 * Fetch today's consumption
 */
export function useTodayConsumption(): UseQueryResult<ConsumptionResponse, Error> {
  return useQuery({
    queryKey: queryKeys.consumption.today(),
    queryFn: () => consumptionApi.getTodayConsumption(),
    staleTime: 60 * 60 * 1000, // 1 hour (consumption data has delay)
  });
}

/**
 * Fetch consumption for a date range
 */
export function useConsumption(
  periodFrom?: Date,
  periodTo?: Date
): UseQueryResult<ConsumptionResponse, Error> {
  return useQuery({
    queryKey: queryKeys.consumption.range(periodFrom, periodTo),
    queryFn: () => consumptionApi.getConsumption(periodFrom, periodTo),
    staleTime: 60 * 60 * 1000, // 1 hour
  });
}

/**
 * Fetch daily consumption
 */
export function useDailyConsumption(days: number = 30) {
  return useQuery({
    queryKey: queryKeys.consumption.daily(days),
    queryFn: () => consumptionApi.getDailyConsumption(days),
    staleTime: 60 * 60 * 1000, // 1 hour
  });
}

// ============ Analysis Hooks ============

/**
 * Fetch full dashboard data
 */
export function useDashboard(): UseQueryResult<DashboardResponse, Error> {
  return useQuery({
    queryKey: queryKeys.analysis.dashboard(),
    queryFn: () => analysisApi.getDashboard(),
    refetchInterval: 5 * 60 * 1000, // Refetch every 5 minutes
    staleTime: 60 * 1000, // Consider stale after 1 minute
  });
}

/**
 * Fetch period summary
 */
export function useSummary(
  period: 'today' | 'yesterday' | 'week' | 'month'
): UseQueryResult<PeriodSummary, Error> {
  return useQuery({
    queryKey: queryKeys.analysis.summary(period),
    queryFn: () => analysisApi.getSummary(period),
    staleTime: 5 * 60 * 1000,
  });
}

/**
 * Fetch usage recommendations
 */
export function useRecommendations(
  hoursAhead: number = 24
): UseQueryResult<RecommendationsResponse, Error> {
  return useQuery({
    queryKey: queryKeys.analysis.recommendations(hoursAhead),
    queryFn: () => analysisApi.getRecommendations(hoursAhead),
    staleTime: 15 * 60 * 1000, // 15 minutes
  });
}

// ============ Health Hook ============

/**
 * Check API health
 */
export function useHealth(): UseQueryResult<HealthResponse, Error> {
  return useQuery({
    queryKey: queryKeys.health,
    queryFn: () => healthApi.check(),
    staleTime: 60 * 1000,
    retry: 3,
  });
}
