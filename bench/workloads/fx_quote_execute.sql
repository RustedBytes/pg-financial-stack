SELECT fx_execute_quote((fx_create_quote(
  'USD 1.00'::money_with_currency, 'EUR', customer_id => 'bench-customer'
)).id);

