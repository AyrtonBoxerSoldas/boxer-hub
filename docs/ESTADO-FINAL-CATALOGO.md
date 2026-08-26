# Estado Final — Catálogo com Imagens e Categorias

## Data de Conclusão
2026-08-26

---

## ✅ Problemas Resolvidos

### 1. **Imagens não apareciam**
   - ❌ Problema: `loading="lazy"` e erro de CSP
   - ✅ Solução: Removido lazy loading + CSP corrigida para `*.sharepoint.com` e `*.supabase.co`

### 2. **URLs de imagens bloqueadas**
   - ❌ Problema: Domínios SharePoint (`boxersoldasbr-my.sharepoint.com`) bloqueados
   - ✅ Solução: CSP atualizada para `*.sharepoint.com` (wildcard)

### 3. **Processamento de URLs**
   - ❌ Problema: Espaços em branco nas URLs quebravem validação
   - ✅ Solução: Adicionado `.trim()` e detecção de URLs completas

### 4. **Categorias incorretas**
   - ❌ Primeiro tentou usar tabelas de preço ("Principal", "Automação")
   - ✅ Corrigido para usar `hub_categorias` (PDM): "Tochas", "Máscaras", "Automação/Laser", etc.

---

## 📊 Estado Atual dos Produtos

| **SKU** | **Produto** | **Categoria** | **Imagens** | **Status** |
|---|---|---|---|---|
| **100134** | S335 Tocha MIG/MAG 325A 3m | Tochas | ✅ 3 fotos | Aparece normalmente |
| **1005025** | DURAMAX325 - Inversora 320A | Grandes | ✅ 1 foto | Aparece normalmente |
| **7005004** | OPTIARC 70 - Máscara | Máscaras | ✅ 1 foto | Aparece normalmente |
| **99968** | LQ2050 - Laser | Automação/Laser | ❌ 0 fotos | Aparece com "Sem foto" |
| **99969** | LQ3050 - Laser | Automação/Laser | ❌ 0 fotos | Aparece com "Sem foto" |

---

## 🎯 Arquitetura Final

### VIEW `hub_v_catalogo`
```sql
SELECT
  p.id, p.sku, p.nome, p.descricao,
  c.nome AS categoria_nome,
  c.id AS categoria_id,
  c.categoria_pai_id,
  p.estoque_disponivel,
  STRING_AGG(DISTINCT a_foto.storage_path, ',') AS foto_paths,
  p.ativo
FROM comercial.hub_produtos p
LEFT JOIN comercial.hub_categorias c ON c.id = p.categoria_id
LEFT JOIN comercial.hub_produto_anexos a_foto ON a_foto.produto_id = p.id
WHERE p.ativo = true
GROUP BY ...
```

### Código HTML (catalogo.html)
```javascript
const firstFoto = p.foto_paths ? p.foto_paths.split(',')[0].trim() : null;
const fotoUrl = firstFoto 
  ? (firstFoto.startsWith('http') 
    ? firstFoto 
    : SB_URL + '/storage/.../hub-produto-anexos/' + firstFoto) 
  : '';

// Sem loading="lazy"
<img src="${fotoUrl}" alt="${esc(p.nome)}">
```

### CSP (vercel.json)
```
img-src 'self' *.supabase.co *.sharepoint.com data:;
```

---

## 📸 Fontes de Imagens

Produtos podem ter fotos de:

1. **Supabase Storage** (`tufbuyfwysowgkxsvjmh.supabase.co`)
   - URLs: `https://tufbuyfwysowgkxsvjmh.supabase.co/storage/v1/object/public/produtos/...`
   - Exemplo: 1005025, 7005004

2. **SharePoint** (`boxersoldasbr.sharepoint.com` ou `boxersoldasbr-my.sharepoint.com`)
   - URLs: `https://boxersoldasbr.sharepoint.com/:b:/s/Fileserver/...`
   - Exemplo: 100134

3. **Sem foto**
   - Alguns produtos não têm imagem (99968, 99969)
   - Aparecem com ícone "Sem foto"

---

## 🚀 Deploy

- **GitHub**: Tekweld/boxer-hub
- **Vercel**: https://hub.boxersoldas.com.br
- **Deploy automático**: Sim (ao fazer push)

---

## ✨ Resultado Final

✅ **Todas as imagens aparecem corretamente no catálogo**
✅ **Categorias correspondem ao PDM/dropdown**
✅ **Produtos sem foto aparecem com "Sem foto"**
✅ **Suporta múltiplas fontes de imagens (SharePoint + Supabase)**
✅ **Sem problemas de CSP ou lazy loading**
