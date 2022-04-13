using Main;

class Main {
	
	static function main() {
		var script = null;
		
		var engine = new bp.hquery.MongoEngine();
		Sys.print("Hscript: ");
		while ((script = Sys.stdin().readLine()) != "end") {
			final parsed = engine.parse(script);
			if(parsed.ok) {
				Sys.println("MongoDB Query: " + haxe.Json.stringify(parsed.result, null, "   "));
			} else {
				Sys.println("Parser Error: " + haxe.Json.stringify(parsed.error, null, "   "));
			}
			Sys.print("Hscript: ");
		}
	}
	
}