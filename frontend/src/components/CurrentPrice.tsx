/**
 * Large current price display component
 */

import { useMemo } from 'react';
import { Zap, TrendingDown, Clock } from 'lucide-react';
import type { PricePeriod } from '../types';
import {
  formatPrice,
  formatTime,
  getPriceCategory,
  getPriceBgClass,
  formatRelativeTime,
  parseDate,
} from '../utils/formatters';

interface CurrentPriceProps {
  currentPrice: PricePeriod | null;
  bestUpcoming: PricePeriod[];
  hasNegativeUpcoming: boolean;
}

export function CurrentPrice({
  currentPrice,
  bestUpcoming,
  hasNegativeUpcoming,
}: CurrentPriceProps) {
  const priceCategory = useMemo(() => {
    if (!currentPrice) return 'normal';
    return getPriceCategory(currentPrice.value_inc_vat);
  }, [currentPrice]);

  const bgColorClass = useMemo(() => {
    if (!currentPrice) return 'bg-gray-700';
    return getPriceBgClass(currentPrice.value_inc_vat);
  }, [currentPrice]);

  if (!currentPrice) {
    return (
      <div className="bg-gray-800 rounded-2xl p-8 text-center">
        <p className="text-gray-400">Loading current price...</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Main Price Display */}
      <div
        className={`${bgColorClass} rounded-2xl p-8 text-center text-white shadow-lg transition-all duration-300`}
      >
        {priceCategory === 'negative' && (
          <div className="flex items-center justify-center gap-2 mb-2">
            <Zap className="w-6 h-6 animate-pulse" />
            <span className="text-lg font-bold uppercase tracking-wide">You Get Paid!</span>
            <Zap className="w-6 h-6 animate-pulse" />
          </div>
        )}

        <p className="text-sm uppercase tracking-wide opacity-80 mb-2">Current Price</p>

        <p className="text-7xl font-bold tracking-tight">
          {formatPrice(currentPrice.value_inc_vat)}
        </p>

        <p className="text-lg opacity-80 mt-2">per kWh (inc. VAT)</p>

        <div className="flex items-center justify-center gap-2 mt-4 text-sm opacity-70">
          <Clock className="w-4 h-4" />
          <span>
            {formatTime(parseDate(currentPrice.valid_from))} -{' '}
            {formatTime(parseDate(currentPrice.valid_to))}
          </span>
        </div>
      </div>

      {/* Negative Price Alert */}
      {hasNegativeUpcoming && priceCategory !== 'negative' && (
        <div className="bg-emerald-900/50 border border-emerald-500 rounded-xl p-4 flex items-center gap-3">
          <div className="bg-emerald-500 rounded-full p-2">
            <Zap className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-semibold text-emerald-400">Negative prices coming soon!</p>
            <p className="text-sm text-gray-300">Check the best upcoming times below</p>
          </div>
        </div>
      )}

      {/* Best Upcoming Times */}
      {bestUpcoming.length > 0 && (
        <div className="bg-gray-800 rounded-xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <TrendingDown className="w-5 h-5 text-blue-400" />
            <h3 className="font-semibold text-gray-200">Best Upcoming Times</h3>
          </div>

          <div className="space-y-2">
            {bestUpcoming.slice(0, 5).map((period, index) => {
              const time = parseDate(period.valid_from);
              const category = getPriceCategory(period.value_inc_vat);

              return (
                <div
                  key={period.valid_from}
                  className="flex items-center justify-between bg-gray-700/50 rounded-lg px-3 py-2"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-gray-500 text-sm w-4">{index + 1}</span>
                    <div>
                      <p className="font-medium text-gray-200">{formatTime(time)}</p>
                      <p className="text-xs text-gray-400">{formatRelativeTime(time)}</p>
                    </div>
                  </div>
                  <span
                    className={`font-bold ${
                      category === 'negative'
                        ? 'text-emerald-400'
                        : category === 'cheap'
                          ? 'text-blue-400'
                          : 'text-gray-300'
                    }`}
                  >
                    {formatPrice(period.value_inc_vat)}
                  </span>
                </div>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}

export default CurrentPrice;
