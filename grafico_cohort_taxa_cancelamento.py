# Instalar dependências necessárias
# pip install psycopg2 SQLAlchemy pandas seaborn matplotlib

import sqlalchemy
import pandas
import seaborn
import matplotlib.pyplot as plt

engine = sqlalchemy.create_engine('postgresql+psycopg2://postgres:1234@localhost:5432/postgres')

# Query que calcula taxa de cancelamento (churn) por safra de contratação
# "safra" = mês em que o cliente contratou o plano
# "mes" = meses desde a contratação
# Para cada safra, calculamos a proporção média de contratos cancelados ao longo do tempo
query = '''
select 
 	TO_CHAR(contratacao, 'yyyy-mm') as safra,
	mes,
	avg(case when cancelamento < contratacao + make_interval(months => mes) then 1 else 0 end) as taxa_cancelamento
from portfolio.contratos
cross join generate_series(0, (extract(year from age('2025-05-15', '2023-06-01')) * 12 + extract(month from age('2025-05-15', '2023-06-01'))-1)::integer) as mes
where contratacao + make_interval(months => mes) < date_trunc('month', '2025-05-15'::date)
group by safra, mes
order by safra, mes
'''

df = pandas.read_sql_query(query, engine)

print(df.head())

import matplotlib.ticker as ticker
g = seaborn.lineplot(data=df, x='mes', y='taxa_cancelamento', hue='safra', palette='magma_r')

#Ajustes visuais para melhorar legibilidade do gráfico
g.legend(title='safra', fontsize=8)
g.set_title('Cancelamento de plano de celular pós pago')
g.set_xlabel('Meses desde a contratação')
g.set_ylabel('Taxa de cancelamento')
g.set_xlim(0)
g.set_ylim(0)
g.xaxis.set_major_locator(ticker.MultipleLocator(1))
g.yaxis.set_major_formatter(ticker.PercentFormatter(xmax=1.0, decimals=0))

plt.show()