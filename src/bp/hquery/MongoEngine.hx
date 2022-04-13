package bp.hquery;

import hscript.Expr;
import hscript.Interp;

using bp.hquery.MongoEngine;
@:expose
class MongoEngine {
	var logger:Logger;

	public function new(?logger) {
		if (logger != null)
			this.logger = logger;
		else
			this.logger = {
				info: haxe.Log.trace,
				warn: haxe.Log.trace,
				error: haxe.Log.trace
			}
	}

	var interp = new Interp();
	var parser = {
		var p = new hscript.Parser();
		p.opRightAssoc.remove('=');
		p.opPriority.set("=", 5);
		p;
	}

	static var opMap = [
		"||" => "or",
		"&&" => "and",
		"!=" => "ne",
		"==" => "eq",
		">=" => "gte",
		">" => "gt",
		"<=" => "lte",
		"<" => "lt",
		"=" => "eq"
	];

	static inline function _default(?e):Dynamic
		throw "invalid expression " + Std.string(e);

	static inline function findOp(op)
		return if (opMap.exists(op)) {
			opMap[op];
		} else {
			throw 'Invalid operator';
		}

	public function parse(s:String)
		try {
			var parsed = parser.parseString(s);
			return {ok: true, result: convert(parsed, interp), error: null};
		} catch (e:haxe.Exception) {
			logger.error(e, "Error parsing query string");
			return {ok: false, result: null, error: '$e'};
		}

	static inline function parseAccess(e:Expr)
		return (function doParse(prev:Array<String>, e)
			return switch e {
				case EField(eN, f):
					doParse(prev.concat([f]), eN);
				case EIdent(v):
					prev.push(v);
					prev.reverse();
					prev;
				default:
					throw e;
			})([], e);

	static function convert(e:Expr, interp:Interp):Dynamic {
		var convert = convert.bind(_, interp);
		return switch e {
			case EBinop(op, e1, e2):
				var ret = new haxe.DynamicAccess();
				ret['$' + findOp(op)] = [e1, e2].map(convert);
				ret;
			case EField(e, f):
				['${convert(e)}', f].join('.');
			case EConst(_):
				interp.execute(e);
			case EArrayDecl(e):
				e.map(convert);
			case ECall(e, params):
				var args = params.map(convert);
				var access = e.parseAccess();
				var method = access.pop();
				if (access.length > 0)
					args.unshift('$' + access.join('.'));
				Reflect.callMethod(FilterFunctions, Reflect.getProperty(FilterFunctions, method), args);
			case EUnop(_, _, EConst(_)):
				interp.execute(e);
			case EIdent(v): if (v != 'null') '$' + v else null;
			case EParent(e): convert(e);
			default: _default(e);
		}
	}
}

class StaticFilterFunctions {}
typedef ArgList = Array<Dynamic>;

class FilterFunctions {
	public static function now()
		return Date.now();

	public static function date(?year = 0, ?month = 0, ?day = 0, ?hour = 0, ?min = 0, ?sec = 0)
		return new Date(year, month, day, hour, min, sec);

	public static function isIn(field:String, exprs:Array<Dynamic>) {
		var ret = new haxe.DynamicAccess();
		var args:ArgList = [field, exprs];
		ret["$in"] = args;
		return ret;
	}

	public static function substring(field:String, ?start:Int, ?count:Int):Dynamic {
		var ret = new haxe.DynamicAccess();
		var args:ArgList = [field];
		if (start != null)
			args.push(start);
		if (count != null)
			args.push(count);
		ret["$substrBytes"] = args;
		return ret;
	}

	public static function indexOfString(field:String, sub:String, ?start:Int, ?end:Int) {
		var ret = new haxe.DynamicAccess();
		var args:ArgList = [field, sub];
		if (start != null)
			args.push(start);
		if (end != null)
			args.push(end);
		ret["$indexOfBytes"] = args;
		return ret;
	}

	public static function indexOfArray(field:String, expr:Dynamic, ?start:Int, ?end:Int) {
		var ret = new haxe.DynamicAccess();
		var args:ArgList = [field, expr];
		if (start != null)
			args.push(start);
		if (end != null)
			args.push(end);
		ret["$indexOfArray"] = args;
		return ret;
	}
}
