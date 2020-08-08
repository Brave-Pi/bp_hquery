package bp.hquery;

import hscript.Expr;
import hscript.Interp;

using bp.hquery.Engine;

class Engine {
	public function new() {}

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
			'$' + op;
		}

	public function parse(s:String) {
		var parsed = parser.parseString(s);
		return convert(parsed);
	}

	static function convert(expr:Expr)
		return switch expr {
			case EBinop(op, e1, e2):
				var ret = new haxe.DynamicAccess();
				ret['$' + findOp(op)] = [e1, e2].map(reify);
				ret;
			case ECall(e, params):
				expr.reify();
			case EParent(e): e.convert();
			default: _default(expr);
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

	static var interp = new Interp();

	static function reify(e:Expr):Dynamic
		return switch e {
			case EField(e, f):
				['${e.reify}', f].join('.');
			case EConst(_):
				interp.execute(e);
			case EArrayDecl(e):
				e.map(reify);
			case ECall(e, params):
				var args = params.map(reify);
				var access = e.parseAccess();
				var method = access.pop();
				if (access.length > 0)
					args.unshift('$' + access.join('.'));
				Reflect.callMethod(FilterFunctions, Reflect.getProperty(FilterFunctions, method), args);
			case EBinop(_, _, _):
				convert(e);
			case EUnop(_, _, EConst(_)):
				interp.execute(e);
			case EIdent(v): '$' + v;
			case EParent(e): e.reify();
			default: _default(e);
		}
}

class StaticFilterFunctions {}
typedef ArgList = Array<Dynamic>;

class FilterFunctions {
	public static function date(?year = 0, ?month = 0, ?day = 0, ?hour = 0, ?min = 0, ?sec = 0)
		return new Date(year, month, day, hour, min, sec);

	public static function isIn(field:String, exprs:Array<Dynamic>) {
		var ret = new haxe.DynamicAccess();
		var args:ArgList = [field];
		ret["$in"] = args.concat(exprs);
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
