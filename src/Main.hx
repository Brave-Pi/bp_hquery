import bp.hquery.Engine;
using Main;

class Main {
	
	static function main() {
		var script = null;
		
		var engine = new bp.hquery.Engine();
		Sys.print("Hscript: ");
		while ((script = Sys.stdin().readLine()) != "end") {
			Sys.println("MongoDB Query: " + haxe.Json.stringify(engine.parse(script), null, "   "));
		}
	}
	
}