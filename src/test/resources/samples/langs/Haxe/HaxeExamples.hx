using StringTools;

/***** INHERITANCE *****/
class Parent {
  public var seen = [];
  public function new() {
    seen.push("parent");
  }
}
class Child extends Parent {
  override public function new(){
    super(); // mandatory, and only works from new, for some reason :/
    seen.push("child");
  }
}

class HaxeExamples {
  /***** ATTRIBUTES *****/
  // instance vs class attributes
  var instanceAttribute:String;
  static var classAttribute:String;

  // public vs private attributes
  public var publicAttribute:String;
  private var privateAttribute:String;
  public static var publicClassAttribute:String;

  // default value
  var varWithDefault = 'somestring';

  // disambiguating local var from attribute
  var someValue = 1;
  function disambiguateLocalFromAttribute():Int {
    var someValue = 2;
    return this.someValue + someValue; // 3
  }

  /***** METHODS *****/
  // public vs private function
  public function publicMethod() { }
  private function privateMethod() { }

  // instance function vs class function
  function instanceMethod() { }
  static function classMethod() { }
  private static function privateClassMethod() {}

  // with typed arg
  function withTypedArg(arg:String) { }

  // with return type
  function withReturnType():String { return "zomg"; }

  // with no return type (aka side-effect city)
  function withNoReturnType():Void { }

  // with generic type
  function withGenericType<T>(something:T) { }

  // rebind methods with dynamic
  public dynamic function toRebind() { return "Original"; }

  // since brackets group expressions, a single expression does not need a group
  function noBrackets() return this;

  /***** MORE EXAMPLES!! *****/
  public static function main() {
    var haxeExamples = new HaxeExamples();

    // trace is a puts statement that tells you where it came from
    // it's documented at haxe.Log.trace
    trace("Hello World!");

    // real stdout
    Sys.stdout().writeString("\033[32mnormal print statement \033[0m(with ansi escape codes embedded)\n");

    // argv
    Sys.args();

    // overridden methods
    trace(new Child().seen);

    // disambiguating
    trace(haxeExamples.disambiguateLocalFromAttribute());

    // rebinding methods
    var originalAndRebound = haxeExamples.toRebind() + " -> ";
    haxeExamples.toRebind = function() { return "Rebound"; }
    originalAndRebound += haxeExamples.toRebind();
    trace(originalAndRebound);

    // methods whose bodies have no brackets
    trace(haxeExamples.noBrackets());

    // local var with explicitly typed arg
    var someNum:Int = 123;

    // reading a file
    var body = sys.io.File.getContent('to_be_read.txt');

    // adding methods to a class
    // this comes from StringTools, but b/c first arg is a String (ie `this`)
    // and we declared we were `using` it, it will match type sigs until it finds the correct one
    trace(body.rtrim());

    // parsing json
    var json = haxe.Json.parse('{"whereDidYouComeFrom":"I came from the jsons"}');
    trace(json.whereDidYouComeFrom);

    /***** BOOLS / LOGIC *****/
    trace(true == true);
    trace(true != true);
    if(true)               trace("if with no else");     // if
    if(!true)              trace("first conditional");   // if with else
    else if(true && false) trace("second conditional");  // conjunction
    else if(true || false) trace("third conditional");   // disjunction
    if(false && {trace("short-circuited"); true;}) null; // conditionals short-circuit

    /***** REFLECTION *****/
    // http://api.haxe.org/haxe/PosInfos.html
    // http://haxe.org/manual/std-reflection.html
    // http://api.haxe.org//Reflect.html
    // http://api.haxe.org//Type.html
    // there's some metaprogramming in here, too, but Imma ignore it for now, b/c eff that amirite?

    // compiler macros
    var infos = function(?infos:haxe.PosInfos) { return infos; }(); // idk how else to get it to set the var other than to receive it as the last function arg
    trace(infos.fileName);   // "HaxeExamples.hx"
    trace(infos.lineNumber); // 77, b/c that's where it got set
    trace(infos.methodName); // "main"
    trace(infos.className);  // HaxeExamples

    // what type?
    trace(Type.typeof(haxeExamples.toRebind));

    // classes
    trace(Type.resolveClass('Parent'));    // Object.const_get :Parent
    trace(Type.resolveClass('NotAThing')); // Object.const_get :NotAThing if Object.constants.include?(:NotAThing)

    trace(Type.getSuperClass(Child));  // Child.superclass
    trace(Type.getSuperClass(Parent)); // BasicObject.superclass

    trace(Type.getClass(haxeExamples)); // haxe_examples.class
    trace(Type.getClassName(Child));    // Child.name

    // attributes
    trace(Reflect.fields({a:1, b:2}));           // {a:1, b:2}.keys
    trace(Type.getInstanceFields(HaxeExamples)); // HaxeExamples.instance_methods

    trace(Reflect.hasField({a: 1}, "a"));  // {a: 1}.key? :a
    trace(Reflect.hasField({a: 1}, "b"));  // {a: 1}.key? :b

    trace(Reflect.field({a:1, b:2}, "a")); // {a:1}[:a]

    // enums
    // Type.resolveEnum('SomeEnum')
    // Type.getEnumName(SomeEnum)
    // Type.getEnumConstructs(SomeEnum)
    // Type.getEnum(someEnum)
    // Type.enumParameters(someEnum)
    // Type.enumIndex(someEnum)
    // Type.enumEq(someEnum, someOtherEnum)
    // Type.enumConstructor(someEnum, someOtherEnum)
    // Type.allEnums(someEnum)



    /***** TYPES *****/
    // Basic types. And here's a list of operators http://haxe.org/manual/types-numeric-operators.html
    var b:Bool  = true;
    var f:Float = 1.2;
    var i:Int   = 3;

    var nonNullableInt         = function(arg  : Int = 0 ) return arg;
    var nullableInt            = function(?arg : Int     ) return arg;
    var nullableIntWithDefault = function(?arg : Int = -1) return arg;

    trace('nonNullableInt(123)  ->', nonNullableInt(123));
    trace('nonNullableInt()     ->', nonNullableInt());
    trace('nonNullableInt(null) ->', nonNullableInt(null));

    trace('nullableInt(123)  ->', nullableInt(123));
    trace('nullableInt()     ->', nullableInt());
    trace('nullableInt(null) ->', nullableInt(null));

    trace('nullableIntWithDefault(123)  ->', nullableIntWithDefault(123));
    trace('nullableIntWithDefault()     ->', nullableIntWithDefault());
    trace('nullableIntWithDefault(null) ->', nullableIntWithDefault(null));

  }
}
