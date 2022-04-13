# Haxe project

This is an example Haxe project scaffolded by Visual Studio Code.

Without further changes the structure is following:

 * `src/Main.hx`: Entry point Haxe source file
 * `build.hxml`: Haxe command line file used to build the project
 * `README.md`: This file

# BP HQuery

Convert Hscript expressions into MongoDB queries (using [aggregation pipeline operators](https://docs.mongodb.com/manual/reference/operator/aggregation/)).

Also supports the JS `sequelize` library.

## Usage

### Mongo Engine
Run:
`haxe build mongo.hxml`

Then:
```js
const {MongoEngine} = require('./bin/js/mongo-engine').bp.hquery;
const engine = new MongoEngine();
const parsed = engine.parse("x == 5 && y <= 10");
if(parsed.ok) {
   console.log(parsed.result);
} else {
   console.error(parsed.error);
}
```

### Sequelize Engine
Run:
`haxe build sequelize.hxml`

Then:
```js
const {SequelizeEngine} = require('./bin/js/sequelize-engine').bp.hquery;
const engine = new SequelizeEngine();
const parsed = engine.parse("foo.like('%bar%') && baz.notLike('%qux%')");
if(parsed.ok) {
   console.log(parsed.result);
} else {
   console.error(parsed.error);
}
```

## Examples
```haxe
foo == bar
```
becomes:
```json
{
   "$eq": [
      "$foo",
      "$bar"
   ]
}
```

```haxe
foo == "baz"
```
becomes:
```json
{
   "$eq": [
      "$foo",
      "baz"
   ]
}
```


```haxe
val.isIn([1,2,3])
```
becomes:
```json
 {
   "$in": [
      "$val",
      [
         1,
         2,
         3
      ]
   ]
}

```
```haxe
(x < 10 && y > 10) || (x > -10 && y < -10)
```
becomes:
```json
{
   "$or": [
      {
         "$and": [
            {
               "$lt": [
                  "$x",
                  10
               ]
            },
            {
               "$gt": [
                  "$y",
                  10
               ]
            }
         ]
      },
      {
         "$and": [
            {
               "$gt": [
                  "$x",
                  -10
               ]
            },
            {
               "$lt": [
                  "$y",
                  -10
               ]
            }
         ]
      }
   ]
}
```