/**
 * Estadísticas del panel admin, calculadas a partir de los pedidos pagados.
 *
 * Para un catálogo en crecimiento esto es suficiente; a gran escala conviene
 * mantener contadores agregados (incrementales) en `configuracion/stats`.
 */
import { orderRepository } from '../repositories/order.repository.js';
import { ORDER_STATUS } from '../shared/constants/orderStates.js';

const PAID_STATUSES = new Set([
  ORDER_STATUS.PAID,
  ORDER_STATUS.PREPARING,
  ORDER_STATUS.DISPATCHED,
  ORDER_STATUS.IN_TRANSIT,
  ORDER_STATUS.DELIVERED,
]);

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  return new Date(value);
}

export const statsService = {
  async dashboard() {
    const orders = await orderRepository.all({ limit: 2000 });
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfDay);
    startOfWeek.setDate(startOfDay.getDate() - 6);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfYear = new Date(now.getFullYear(), 0, 1);

    let revenue = 0;
    let salesCount = 0;
    const sales = {
      daily: { count: 0, amount: 0 },
      weekly: { count: 0, amount: 0 },
      monthly: { count: 0, amount: 0 },
      yearly: { count: 0, amount: 0 },
    };
    const productMap = new Map();
    const customerMap = new Map();

    for (const order of orders) {
      if (!PAID_STATUSES.has(order.status)) continue;
      const total = Number(order.total) || 0;
      const created = toDate(order.createdAt) ?? now;

      revenue += total;
      salesCount += 1;
      if (created >= startOfDay) bump(sales.daily, total);
      if (created >= startOfWeek) bump(sales.weekly, total);
      if (created >= startOfMonth) bump(sales.monthly, total);
      if (created >= startOfYear) bump(sales.yearly, total);

      for (const item of order.items ?? []) {
        const key = item.productId;
        const entry = productMap.get(key) ?? {
          productId: key,
          name: item.name,
          quantity: 0,
          revenue: 0,
        };
        entry.quantity += Number(item.quantity) || 0;
        entry.revenue += (Number(item.unitPrice) || 0) * (Number(item.quantity) || 0);
        productMap.set(key, entry);
      }

      if (order.userId) {
        const c = customerMap.get(order.userId) ?? {
          userId: order.userId,
          orders: 0,
          total: 0,
        };
        c.orders += 1;
        c.total += total;
        customerMap.set(order.userId, c);
      }
    }

    const topProducts = [...productMap.values()]
      .sort((a, b) => b.quantity - a.quantity)
      .slice(0, 5);
    const topCustomers = [...customerMap.values()]
      .sort((a, b) => b.total - a.total)
      .slice(0, 5);

    return {
      totals: {
        revenue,
        orders: salesCount,
        averageTicket: salesCount > 0 ? revenue / salesCount : 0,
      },
      sales,
      topProducts,
      topCustomers,
    };
  },
};

function bump(bucket, amount) {
  bucket.count += 1;
  bucket.amount += amount;
}
