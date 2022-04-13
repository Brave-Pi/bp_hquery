package bp.hquery;

import hscript.Expr;
import hscript.Interp;
using StringTools;
using bp.hquery.SequelizeEngine;
typedef ParseOpts = {
	decodeUriStrings:Dynamic
}
@:expose
class SequelizeEngine {
	var sequelize:Dynamic;
	var logger:Logger;
	public function new(sequelize, ?logger) {
		this.sequelize = sequelize;
		if(logger != null) this.logger = logger;
		else this.logger = {
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

	static var statementOps = ['and', 'or'];

	static inline function _default(?e):Dynamic
		throw "invalid expression " + Std.string(e);

	static inline function findOp(op)
		return if (opMap.exists(op)) {
			opMap[op];
		} else {
			throw 'Invalid operator';
		}

	public function parse(s:String, ?opts:ParseOpts) try {
		var parsed = parser.parseString(s);
		return {ok: true, result: convert(parsed, interp, this.sequelize, opts), error: null};
	} catch(e:haxe.Exception) {
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

	static function convert(e:Expr, interp:Interp, sequelize:Dynamic, ?opts:ParseOpts):Dynamic {
		if(opts == null) opts = {decodeUriStrings: false};
		var convert = convert.bind(_, interp, sequelize, opts);
		return switch e {
			case EBinop(op, e1, e2):
				final ret = new haxe.DynamicAccess();
				final sequelizeOp = findOp(op);
				if (statementOps.indexOf(sequelizeOp) != -1)
					js.Syntax.code('{0}[{1}.Op[{2}]] = {3};', ret, sequelize, sequelizeOp, [e1, e2].map(convert));
				else
					js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, sequelizeOp, convert(e2), convert(e1));
				ret;
			case EField(e, f):
				'$$${['${convert(e)}', f].join('.')}$$';
			case EConst(Const.CString(uriString)) if(js.Syntax.code("{0}", opts.decodeUriStrings)):
				uriString.urlDecode();
			case EConst(_):
				interp.execute(e);
			case EArrayDecl(e):
				e.map(convert);
			case ECall(e, params):
				var args = params.map(convert);
				var access = e.parseAccess();
				var method = access.pop();
				if (access.length > 0) {
					args.unshift(sequelize);
					args.unshift(if(access.length > 1) '$$${access.join('.')}$$' else access.join('.'));
				}
				Reflect.callMethod(FilterFunctions, Reflect.getProperty(FilterFunctions, method), args);
			case EUnop(_, _, EConst(_)):
				interp.execute(e);
			case EIdent(v): if (v != 'null') v else null;
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

	public static function isIn(field:String, sequelize:Dynamic, exprs:Array<Dynamic>) {
		var ret = new haxe.DynamicAccess();
		// var args:ArgList = [field, exprs];
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "in", exprs, field);
		return ret;
	}

	public static function like(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "like", operand, field);
		return ret;
	}
	
	public static function endsWith(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "endsWith", operand, field);
		return ret;
	}

	public static function startsWith(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "startsWith", operand, field);
		return ret;
	}

	public static function regexp(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "regexp", operand, field);
		return ret;
	}

	public static function notRegexp(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "notRegexp", operand, field);
		return ret;
	}
	public static function substring(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "substring", operand, field);
		return ret;
	}
	public static function notLike(field:String, sequelize:Dynamic, operand:String) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "notLike", operand, field);
		return ret;
	}

	public static function between(field:String, sequelize:Dynamic, exprs:Array<Dynamic>) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "between", exprs, field);
		return ret;
	}

	public static function notBetween(field:String, sequelize:Dynamic, exprs:Array<Dynamic>) {
		var ret = new haxe.DynamicAccess();
		
		js.Syntax.code('{0}[{4}] = {[{1}.Op[{2}]]: {3}}', ret, sequelize, "notBetween", exprs, field);
		return ret;
	}

	
}
