/**
 * API service for communicating with the backend
 */

import axios, { AxiosError, AxiosInstance } from 'axios';
import type {
  PricesResponse,
  CurrentPriceResponse,
  ConsumptionResponse,
  DashboardResponse,
  RecommendationsResponse,
  PeriodSummary,
  HealthResponse,
  ApiError,
  PriceStats,
} from '../types';

// API base URL - use environment variable or default to localhost
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Error handler
const handleApiError = (error: AxiosError<ApiError>): never => {
  if (error.response) {
    const message = error.response.data?.detail || 'An error occurred';
    throw new Error(message);
  }
  if (error.request) {
    throw new Error('No response from server. Please check your connection.');
  }
  throw new Error(error.message || 'An unexpected error occurred');
};

// ============ Price API ============

export const pricesApi = {
  /**
   * Get prices for a date range
   */
  async getPrices(periodFrom?: Date, periodTo?: Date): Promise<PricesResponse> {
    try {
      const params: Record<string, string> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      
      const response = await apiClient.get<PricesResponse>('/prices', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get current price and upcoming periods
   */
  async getCurrentPrice(): Promise<CurrentPriceResponse> {
    try {
      const response = await apiClient.get<CurrentPriceResponse>('/prices/current');
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get price statistics
   */
  async getStats(periodFrom?: Date, periodTo?: Date): Promise<PriceStats> {
    try {
      const params: Record<string, string> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      
      const response = await apiClient.get<PriceStats>('/prices/stats', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get hourly aggregated prices
   */
  async getHourlyPrices(periodFrom?: Date, periodTo?: Date) {
    try {
      const params: Record<string, string> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      
      const response = await apiClient.get('/prices/hourly', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get negative price periods
   */
  async getNegativePrices(days: number = 7) {
    try {
      const response = await apiClient.get('/prices/negative', { params: { days } });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },
};

// ============ Consumption API ============

export const consumptionApi = {
  /**
   * Get consumption data for a date range
   */
  async getConsumption(periodFrom?: Date, periodTo?: Date): Promise<ConsumptionResponse> {
    try {
      const params: Record<string, string> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      
      const response = await apiClient.get<ConsumptionResponse>('/consumption', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get today's consumption
   */
  async getTodayConsumption(): Promise<ConsumptionResponse> {
    try {
      const response = await apiClient.get<ConsumptionResponse>('/consumption/today');
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get consumption statistics
   */
  async getStats(periodFrom?: Date, periodTo?: Date) {
    try {
      const params: Record<string, string> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      
      const response = await apiClient.get('/consumption/stats', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get daily consumption totals
   */
  async getDailyConsumption(days: number = 30) {
    try {
      const response = await apiClient.get('/consumption/daily', { params: { days } });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },
};

// ============ Analysis API ============

export const analysisApi = {
  /**
   * Get full dashboard data in one request
   */
  async getDashboard(): Promise<DashboardResponse> {
    try {
      const response = await apiClient.get<DashboardResponse>('/analysis/dashboard');
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get cost analysis
   */
  async getCostAnalysis(periodFrom?: Date, periodTo?: Date, flatRate?: number) {
    try {
      const params: Record<string, string | number> = {};
      if (periodFrom) params.period_from = periodFrom.toISOString();
      if (periodTo) params.period_to = periodTo.toISOString();
      if (flatRate) params.flat_rate_comparison = flatRate;
      
      const response = await apiClient.get('/analysis/cost', { params });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get period summary (today, yesterday, week, month)
   */
  async getSummary(period: 'today' | 'yesterday' | 'week' | 'month'): Promise<PeriodSummary> {
    try {
      const response = await apiClient.get<PeriodSummary>('/analysis/summary', {
        params: { period },
      });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },

  /**
   * Get usage recommendations
   */
  async getRecommendations(hoursAhead: number = 24): Promise<RecommendationsResponse> {
    try {
      const response = await apiClient.get<RecommendationsResponse>('/analysis/recommendations', {
        params: { hours_ahead: hoursAhead },
      });
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },
};

// ============ Health Check ============

export const healthApi = {
  /**
   * Check API health
   */
  async check(): Promise<HealthResponse> {
    try {
      const response = await apiClient.get<HealthResponse>('/health');
      return response.data;
    } catch (error) {
      throw handleApiError(error as AxiosError<ApiError>);
    }
  },
};

// Export default client for custom requests
export default apiClient;
