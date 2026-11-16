// Abre links curtos do Google Maps (maps.app.goo.gl) e devolve o link completo,
// que tem as coordenadas. Só aceita links do Google Maps.
module.exports = async (req, res) => {
  const url = String(req.query.url || '');
  if (!/^https:\/\/(maps\.app\.goo\.gl|goo\.gl\/maps)\//.test(url)) return res.status(400).json({ erro: 'link inválido' });
  try {
    let atual = url;
    for (let i = 0; i < 5; i++) {
      const r = await fetch(atual, { redirect: 'manual' });
      const prox = r.headers.get('location');
      if (!prox) break;
      atual = new URL(prox, atual).toString();
      if (/[-\d.]+,[-\d.]+/.test(decodeURIComponent(atual))) break;
    }
    res.setHeader('Cache-Control', 's-maxage=86400');
    res.json({ url: atual });
  } catch (e) { res.status(502).json({ erro: 'falhou' }); }
};
