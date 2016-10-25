# Rainier
Asp.net core performance and reliability testing automation

hahahah

#POST Method
     [HttpPost]
        public ActionResult Create(string objectJson)
        {
            var req = Request.InputStream;
            req.Seek(0, SeekOrigin.Begin);
            var json = new StreamReader(req).ReadToEnd();
            Tile result = null;
            try
            {
                result = JsonConvert.DeserializeObject<Tile>(json);
            }
            catch(Exception ex)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }

            return null;
        }
