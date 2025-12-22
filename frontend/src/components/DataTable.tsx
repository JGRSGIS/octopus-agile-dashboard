/**
 * Interactive data table using AG Grid
 */

import { useMemo, useCallback, useRef } from 'react';
import { AgGridReact } from 'ag-grid-react';
import type { ColDef, ValueFormatterParams, ICellRendererParams } from 'ag-grid-community';
import 'ag-grid-community/styles/ag-grid.css';
import 'ag-grid-community/styles/ag-theme-alpine.css';

import type { CostPeriod, PricePeriod, ConsumptionPeriod } from '../types';
import {
  formatPrice,
  formatKwh,
  formatCostPence,
  formatTime,
  parseDate,
  getPriceCategory,
} from '../utils/formatters';

// Price cell renderer with color
function PriceCellRenderer({ value }: ICellRendererParams) {
  if (value === null || value === undefined) return null;
  
  const category = getPriceCategory(value);
  const colorClasses: Record<string, string> = {
    negative: 'text-emerald-400 font-bold',
    cheap: 'text-blue-400',
    normal: 'text-yellow-400',
    expensive: 'text-orange-400',
    veryExpensive: 'text-red-400 font-bold',
  };

  return (
    <span className={colorClasses[category]}>
      {formatPrice(value)}
    </span>
  );
}

interface DataTableProps {
  data: CostPeriod[] | PricePeriod[] | ConsumptionPeriod[];
  type: 'cost' | 'prices' | 'consumption';
  height?: string | number;
}

export function DataTable({ data, type, height = 400 }: DataTableProps) {
  const gridRef = useRef<AgGridReact>(null);

  // Transform data based on type
  const rowData = useMemo(() => {
    return data.map((item, index) => {
      const baseRow = { id: index };

      if ('cost_pence' in item) {
        // CostPeriod
        return {
          ...baseRow,
          time: formatTime(parseDate(item.interval_start)),
          intervalStart: item.interval_start,
          consumption: item.consumption_kwh,
          price: item.price_pence,
          cost: item.cost_pence,
        };
      } else if ('consumption' in item) {
        // ConsumptionPeriod
        return {
          ...baseRow,
          time: formatTime(parseDate(item.interval_start)),
          intervalStart: item.interval_start,
          consumption: item.consumption,
        };
      } else {
        // PricePeriod
        return {
          ...baseRow,
          time: formatTime(parseDate(item.valid_from)),
          intervalStart: item.valid_from,
          priceExcVat: item.value_exc_vat,
          priceIncVat: item.value_inc_vat,
        };
      }
    });
  }, [data]);

  // Column definitions based on type
  const columnDefs: ColDef[] = useMemo(() => {
    const baseColumns: ColDef[] = [
      {
        field: 'time',
        headerName: 'Time',
        width: 100,
        pinned: 'left',
      },
    ];

    if (type === 'cost') {
      return [
        ...baseColumns,
        {
          field: 'consumption',
          headerName: 'Usage (kWh)',
          width: 120,
          valueFormatter: (params: ValueFormatterParams) =>
            params.value ? formatKwh(params.value) : '',
        },
        {
          field: 'price',
          headerName: 'Price (p/kWh)',
          width: 130,
          cellRenderer: PriceCellRenderer,
        },
        {
          field: 'cost',
          headerName: 'Cost',
          width: 100,
          valueFormatter: (params: ValueFormatterParams) =>
            params.value ? formatCostPence(params.value) : '',
        },
      ];
    } else if (type === 'consumption') {
      return [
        ...baseColumns,
        {
          field: 'consumption',
          headerName: 'Usage (kWh)',
          flex: 1,
          valueFormatter: (params: ValueFormatterParams) =>
            params.value ? formatKwh(params.value) : '',
        },
      ];
    } else {
      // prices
      return [
        ...baseColumns,
        {
          field: 'priceExcVat',
          headerName: 'Exc. VAT',
          width: 110,
          valueFormatter: (params: ValueFormatterParams) =>
            params.value ? formatPrice(params.value) : '',
        },
        {
          field: 'priceIncVat',
          headerName: 'Inc. VAT',
          width: 110,
          cellRenderer: PriceCellRenderer,
        },
      ];
    }
  }, [type]);

  // Default column definition
  const defaultColDef: ColDef = useMemo(
    () => ({
      sortable: true,
      filter: true,
      resizable: true,
    }),
    []
  );

  // Export to CSV
  const exportToCsv = useCallback(() => {
    gridRef.current?.api?.exportDataAsCsv({
      fileName: `octopus-${type}-${new Date().toISOString().split('T')[0]}.csv`,
    });
  }, [type]);

  return (
    <div className="bg-gray-800 rounded-xl p-4">
      <div className="flex justify-between items-center mb-4">
        <h3 className="text-gray-200 font-medium">
          {type === 'cost'
            ? 'Cost Breakdown'
            : type === 'consumption'
            ? 'Consumption Data'
            : 'Price Data'}
        </h3>
        <button
          onClick={exportToCsv}
          className="px-3 py-1 bg-gray-700 hover:bg-gray-600 rounded text-sm text-gray-300 transition-colors"
        >
          Export CSV
        </button>
      </div>

      <div
        className="ag-theme-alpine-dark"
        style={{ height: typeof height === 'number' ? `${height}px` : height, width: '100%' }}
      >
        <AgGridReact
          ref={gridRef}
          rowData={rowData}
          columnDefs={columnDefs}
          defaultColDef={defaultColDef}
          animateRows={true}
          pagination={true}
          paginationPageSize={20}
          paginationPageSizeSelector={[10, 20, 50, 100]}
        />
      </div>
    </div>
  );
}

export default DataTable;
