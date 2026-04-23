# MagistralChat — Patches & Customizações

Esta pasta contém todos os arquivos customizados do MagistralChat.
Quando fizer um novo fork do Chatwoot, copie estes arquivos para os destinos indicados.

---

## Arquivos e onde copiar

| Arquivo nesta pasta | Destino no repositório | O que faz |
|---|---|---|
| `chatwoot_hub.rb` | `lib/chatwoot_hub.rb` | Adiciona rescue blocks em todas as chamadas HTTP externas (evita erro 500). Fallbacks para `enterprise` e `9999999`. |
| `enterprise_setup.rb` | `db/seeders/enterprise_setup.rb` | Script idempotente que configura o banco como enterprise a cada deploy. |
| `rails.sh` | `docker/entrypoints/rails.sh` | Entrypoint que chama o enterprise_setup.rb automaticamente na inicialização do container. |
| `show.html.erb` | `app/views/super_admin/settings/show.html.erb` | Corrige erro 500: adiciona `.to_i` na comparação `pricing_plan_quantity`. |

---

## Como usar num novo fork

### 1. Faça o fork do Chatwoot
```
https://github.com/chatwoot/chatwoot → Fork
```

### 2. Clone localmente
```bash
git clone https://github.com/SEU_USUARIO/chatwoot
cd chatwoot
```

### 3. Copie os arquivos desta pasta para os destinos
```bash
cp magistralchat-patches/chatwoot_hub.rb lib/chatwoot_hub.rb
cp magistralchat-patches/enterprise_setup.rb db/seeders/enterprise_setup.rb
cp magistralchat-patches/rails.sh docker/entrypoints/rails.sh
cp magistralchat-patches/show.html.erb app/views/super_admin/settings/show.html.erb
```

### 4. Configure o GitHub Actions para build Docker
Copie o workflow de `.github/workflows/docker-build.yml` deste repositório para o novo fork.

### 5. Commit e push
```bash
git add .
git commit -m "feat: apply MagistralChat enterprise patches"
git push origin develop
```

### 6. O GitHub Actions vai buildar e publicar a imagem automaticamente.

---

## Configurações aplicadas automaticamente

O `enterprise_setup.rb` configura no banco:

| Config | Valor |
|---|---|
| INSTALLATION_NAME | MagistralChat |
| INSTALLATION_PRICING_PLAN | enterprise |
| INSTALLATION_PRICING_PLAN_QUANTITY | 9999999 |
| BRAND_NAME | MagistralChat |
| BRAND_URL | valor da env FRONTEND_URL |
| WIDGET_BRAND_URL | valor da env FRONTEND_URL |

---

## Observações

- O `rails.sh` só roda o enterprise_setup quando `RAILS_ENV != test`
- O script é **idempotente** — seguro rodar múltiplas vezes
- O `chatwoot_hub.rb` tem fallbacks: se o banco não tiver o plano definido, retorna `enterprise` por padrão
- A correção no `show.html.erb` é necessária porque o banco retorna `pricing_plan_quantity` como String e a view precisa de Integer para a comparação
