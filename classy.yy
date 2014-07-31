%token T_INC "++ (T_INC)"
%token T_ECHO       "echo (T_ECHO)"

%%
start 
    : top_statement_list
    ;

top_statement_list
    :  top_statement_list top_statement
    ;

namespace_name
    : T_STRING
    | namespace_name T_NS_SEPARATOR T_STRING
    ;

top_statement
    : statement
    | function_declaration_statement  // function
    | class_declaration_statement     // class
    | T_HALT_COMPILER '(' ')' ';'     // __halt_compiler
    | T_NAMESPACE namespace_name ';'  // namespace demo
    | T_NAMESPACE namespace_name '{' top_statement_list '}'  // namespace demo {}
    | T_NAMESPACE '{' top_statement_list '}' // 同上
    | T_USE use_declarations ';' use /demo/demo1/demo2 
    | constant_declaration ';'
    ;


statement
    : unticked_statement
    | T_STRING ':'
    ;
// php的主要流程 语法结构
unticked_statement
    : T_IF '(' expr ')' statement elseif_list else_single  // if ($a + $b) *** elseif *** else ***
    | T_IF '(' expr ')' ':' inner_statement_list new_elseif_list new_else_single T_ENDIF ';' // if (***) : *** elseif: *** else: ** endif
    | T_WHILE '(' expr ')' while_statement
    | T_DO statement T_WHILE '(' expr ')' ';'
    | T_FOR '(' for_expr ';' for_expr ';' for_expr ')' for_statement
    | T_SWITCH '(' expr ')'
    | T_BREAK ';'
    | T_BREAK expr ';'
    | T_CONTINUE ';'
    | T_CONTINUE expr ';'
    | T_RETURN ';'
    | T_RETURN expr_without_variable ';'
    | T_RETURN variable ';'
    | T_GLOBAL global_var_list ';'
    | T_STATIC static_var_list ';'
    | T_ECHO echo_expr_list ';'
    | T_INLINE_HTML
    | expr ';'
    | T_UNSET '(' unset_variables ')' ';'
    | T_FOREACH '(' variable T_AS foreach_variable foreach_optional_arg ')' foreach_statement
    | T_DECLARE '(' declare_list ')' declare_statement 
    | ';'
    | T_TRY '{' inner_statement_list '}'
    | T_CATCH '(' fully_qualified_class_name T_VARIABLE ')' '{' inner_statement_list '}' additional_catches // catch(Exception $e) {} , catch(/demo/Exception $e) {} 
    | T_THROW expr ';'
    | T_GOTO T_STRING ';'
    ;

expr
    : r_variable
    | expr_without_variable
    ;

r_variable
    : variable
    ;

w_variable
    : variable
    ;

rw_variable
    : variable
    ;

variable
    : base_variable_with_function_calls T_OBJECT_OPERATOR object_property method_or_not variable_properties 
    | base_variable_with_function_calls
    ;

base_variable_with_function_calls
    : base_variable
    | array_function_dereference
    | function_call
    ;

base_variable
    : reference_variable                 
    | simple_indirect_reference reference_variable  //比如说 reference_variable 为 $a 这个表达式可以捕获 $$$$$$$a 任意$ 符号
    | static_member
    ;

reference_variable
    : reference_variable '[' dim_offset ']' // $this->demo[100]  由于有些模式的约束 你不能写出类似的 $a[100]$this->demo['asdf']
                                            // 因为 T_VARIABLE 被分词工具捕获的时候有前置条件

    | reference_variable '{' expr '}'       // $a = [1,2,3,4,5]
                                            // $b = 3
                                            // echo $a{$b + 1}
    | compound_variable
    ;

compound_variable
    : T_VARIABLE         // $a->demo, $a[100], $a
    | '$' '{' expr '}'   // 符合语句的变量表达式  ${'a' . 'b' . 'c'}
    ;

expr_without_variable
    : T_LIST '(' assignment_list ')' '=' expr 
    | variable '=' expr
    | variable '=' '&' variable 
    | variable '=' '&' T_NEW class_name_reference ctor_arguments
    | T_CLONE expr 
    | variable T_PLUS_EQUAL expr 
    | variable T_MINUS_EQUAL expr
    | variable T_MUL_EQUAL expr
    | variable T_DIV_EQUAL expr
    | variable T_CONCAT_EQUAL expr
    | variable T_MOD_EQUAL expr
    | variable T_AND_EQUAL expr
    | variable T_OR_EQUAL expr
    | variable T_XOR_EQUAL expr
    | variable T_SL_EQUAL expr
    | variable T_SR_EQUAL expr
    | rw_variable T_INC
    | T_INC rw_variable
    | rw_variable T_DEC
    | T_DEC rw_variable
    | expr T_BOOLEAN_OR
    | expr T_BOOLEAN_AND
    | expr T_LOGICAL_OR
    | expr T_LOGICAL_AND
    | expr T_LOGICAL_XOR expr
    | expr '|' expr
    | expr '&' expr
    | expr '^' expr
    | expr '.' expr
    | expr '+' expr
    | expr '-' expr
    | expr '*' expr
    | expr '/' expr
    | expr '%' expr
    | expr T_SL expr
    | expr T_SR expr
    | '+' expr %prec T_INC
    | '-' expr %prec T_INC
    | '!' expr
    | '~' expr
    | expr T_IS_IDENTICAL expr  // ===
    | expr T_IS_NOT_IDENTICAL expr // !==
    | expr T_IS_EQUAL expr
    | expr T_IS_NOT_EQUAL expr
    | expr '<' expr
    | expr T_IS_SMALLER_OR_EQUAL expr
    | expr '>' expr
    | expr T_IS_GREATER_OR_EQUAL expr
    | expr T_INSTANCEOF class_name_reference   // demo() instanceof 
    | '(' expr ')'
    | new_expr
    | '(' new_expr ')'
    | expr '?' expr ':' expr
    | expr '?' ':' expr // (int) ($a + $b) ?: ($c + $d)
    | internal_functions_in_yacc 
    | T_INT_CAST expr  // (int) $a + $b
    | T_DOUBLE_CAST expr // (double) $a + $b
    | T_STRING_CASE expr // (string) $a + $b
    | T_ARRAY_CAST expr // (array) $a + $b
    | T_OBJECT_CAST expr // (object) $a + $b
    | T_BOOL_CAST expr // (bool) $a + $b
    | T_UNSET_CAST expr
    | T_EXIT exit_expr
    | '@' expr          // @mysql_connect()
    | scalar
    | T_ARRAY '(' array_pair_list ')' array(1,2,3,4)
    | '[' array_pair_list ']' // [1,2,3,4]
    | '`' backticks_expr '`' 
    | T_PRINT expr       // print $a + $b
    /**
     * 标准function语法结构   
     * funciton demo ($a, $b) use ($a, $b) { expr }
     * function demo ($a, $b) { expr }
     *
     */

    | function is_reference '('  parameter_list ')' lexical_vars '{' inner_statement_list '}'
    /**
     * static function demo ($a, $b) use ($a, $b) {expr}
     * static function demo ($a, $b) {expr}
     *
     *
     */
    | T_STATIC function is_reference '('  parameter_list ')' lexical_vars '{' inner_statement_list '}'
    ;




class_name_reference
    : class_name
    | dynamic_class_name_reference
    ;

class_name
    : T_STATIC // static
    | namespace_name
    | T_NAMESPACE T_NS_SEPARATOR namespace_name  // namespace /demo/string 因为 namespace 可以为多个 类似 [namespace_name T_NS STRING] T_NS.. STRING  括号内的为一个namespace_name
    | T_NS_SEPARATOR namespace_name  // /demo/demo1/demo2/demo3/classname
    ;

ctor_arguments
    :                                      // 参数是可以为空的 类似 $a = new demo
    | '(' function_call_parameter_list ')' // function 的参数列表 类似 ($a, $b, $c...) 因为 function_call_parameter_list 可以为空 所以 类似 ()
                                           // 如果调用类的话  $a = new demo()  或者 $a = new demo($a, $b...)
    ;

scalar
    : T_STRING_VARNAME
    | class_constant
    | namespace_name
    | T_NAMESPACE T_NS_SEPARATOR namespace_name
    | T_NS_SEPARATOR namespace_name
    | common_scalar
    | '"' encaps_list '"'
    | T_START_HEREDOC encaps_list T_END_HEREDOC
    | T_CLASS_C
    ;

encaps_list
    : encaps_list encaps_var
    | encaps_list T_ENCAPSED_AND_WHITESPACE
    | encaps_var
    | T_ENCAPSED_AND_WHITESPACE encaps_var
    ;

encaps_var
    : T_VARIABLE
    | T_VARIABLE '['
    | T_VARIABLE T_OBJECT_OPERATOR T_STRING
    | T_DOLLAR_OPEN_CURLY_BRACES expr '}'   //${$a+$b}
    | T_DOLLAR_OPEN_CURLY_BRACES T_STRING_VARNAME '[' expr ']' '}' // ${demo}[$a+$b] 
    | T_CURLY_OPEN variable '}' //{$demo}
    ;

class_constant
    : class_name T_PAAMAYIM_NEKUDOTAYIM T_STRING  // demo::func1 
    | variable_class_name T_PAAMAYIM_NEKUDOTAYIM T_STRING // $demo::func1
    ;
exit_expr
    : 
    | '(' ')'       // exit
    | '(' expr ')'  // exit($a + $b)
    ;

internal_functions_in_yacc
    : T_ISSET '(' isset_variables ')'
    | T_EMPTY '(' variable ')' 
    | T_INCLUDE expr
    | T_INCLUDE_ONCE expr
    | T_EVAL '(' expr ')'
    | T_REQUIRE expr
    | T_REQUIRE_ONCE expr
    ;

isset_variables
    : variable
    | isset_variables ',' variable 
    ;

array_pair_list
    :
    | non_empty_array_pair_list possible_comma
    ;

non_empty_array_pair_list
    : non_empty_array_pair_list ',' expr T_DOUBLE_ARROW expr
    | non_empty_array_pair_list ',' expr  
    | expr T_DOUBLE_ARROW expr 
    | expr
    | non_empty_array_pair_list ',' expr T_DOUBLE_ARROW '&' w_variable
    | non_empty_array_pair_list ',' '&' w_variable
    | expr T_DOUBLE_ARROW '&' w_variable
    | '&' w_variable
    |

backticks_expr
    : 
    | T_ENCAPSED_AND_WHITESPACE 
    | encaps_list
    ;

lexical_vars
    : 
    | T_USE
    ;


function_call_parameter_list
    : non_empty_function_call_parameter_list
    |
    ;

non_empty_function_call_parameter_list
    : expr_without_variable  // 最基础的语法结构 加减乘除 比较之类的 
    | variable               // 变量
    | '&' variable           // 变量引用
    | non_empty_function_call_parameter_list ',' expr_without_variable       // 多参数列表  可以杜绝参数最后一个为逗号情况  
    | non_empty_function_call_parameter_list ',' variable                    // 这最后为一个变量 
    | non_empty_function_call_parameter_list ',' '&' w_variable              // 变量引用 
                            // 这个六个组合 完全承载了 function 的所有情况参数
    ;

dim_offset
    : 
    | expr
    ;

simple_indirect_reference
    : '$'
    | simple_indirect_reference '$'
    ;
 
static_member
    : class_name T_PAAMAYIM_NEKUDOTAYIM variable_without_objects // Demo::$a
    | variable_class_name T_PAAMAYIM_NEKUDOTAYIM variable_without_objects // $demo::$a 
    ;

array_function_dereference
    : array_function_dereference '[' dim_offset ']'
    | function_call '[' dim_offset ']'
    ;
function_call
    : namespace_name '(' function_call_parameter_list ')'      //  demo(参数列表)
    | T_NAMESPACE T_NS_SEPARATOR namespace_name '('  function_call_parameter_list ')' // namespace\blah\mine() http://php.net/manual/zh/language.namespaces.nsconstants.php
    | T_NS_SEPARATOR namespace_name '(' function_call_parameter_list ')'              // \blah\mine() 
    | class_name T_PAAMAYIM_NEKUDOTAYIM variable_name '(' function_call_parameter_list ')'  // \blah\mine::demo() 
    | class_name T_PAAMAYIM_NEKUDOTAYIM variable_without_objects '(' function_call_parameter_list ')' // \blah\mine->demo()
    | variable_class_name T_PAAMAYIM_NEKUDOTAYIM variable_name '(' function_call_parameter_list ')'   // $a->{$b + $c}()
    | variable_class_name T_PAAMAYIM_NEKUDOTAYIM variable_without_objects '(' function_call_parameter_list ')' // $a->$b[123]()
    | variable_without_objects  '(' function_call_parameter_list ')'                                           // $$$$b[123]()
    ;

namespace_name
    : T_STRING                   // 字符串  最常见的 function name
    | namespace_name T_NS_SEPARATOR T_STRING  // 类似  /demo/demo1/demo2
    ;

variable_name
    : T_STRING
    | '{' expr '}'
    ;

variable_class_name
    : reference_variable
    ;

variable_without_objects
    : reference_variable
    | simple_indirect_reference reference_variable 
    ;

elseif_list
    :
    | elseif_list T_ESLEIF '(' expr ')'  //多个elseif
    ;

else_single
    :
    | T_ELSE element
    ;

inner_statement_list
    : inner_statement_list inner_statement
    |
    ;

inner_statement
    : statement
    | function_declaration_statement
    | class_declaration_statement
    | T_HALT_COMPILER '(' ')' ';'
    ;

statement
    : unticked_statement
    | T_STRING ':'
    ;

function_declaration_statement
    : unticked_function_declaration_statement
    ;

unticked_function_declaration_statement
    : function is_reference T_STRING '(' parameter_list ')' '{' inner_statement_list '}' // 这是正常的函数 不是匿名函数 也不是类中的成员方法 
                                    // 这个parameter_list  是 non_empty_function_call_parameter_list + non_empty_parameter_list 的组合
                                    // non_empty_function_call_parameter_list 没有 参数修饰符 
                                    // non_empty_parameter_list 有array callable 和 namespace 修饰
                                    // is_reference 可以为 引用 或者 为空
    ;

function
    : T_FUNCTION
    ;

is_reference
    : 
    | &
    ;

parameter_list
    : non_empty_parameter_list
    |
    ;

non_empty_parameter_list
    : optional_class_type T_VARIABLE  // 带或不待修饰符 
    | optional_class_type '&' T_VARIABLE  // array &$demo
    | optional_class_type '&' T_VARIABLE '=' static_scalar  // string &$demo = __FILE__   其实也可以 array &$demo = __FILE__ 在词法分析阶段这种东西是被允许的，但是语法阶段 会报错
    | optional_class_type T_VARIABLE '=' static_scalar // 去掉了引用
        /**
         * 下面这写没啥可说的 就是为了 多参数后面的那个逗号
         *
         *
         */
    | non_empty_parameter_list ',' optional_class_type T_VARIABLE
    | non_empty_parameter_list ',' optional_class_type '&' T_VARIABLE
    | non_empty_parameter_list ',' optional_class_type '&' T_VARIABLE
    | non_empty_parameter_list ',' optional_class_type T_VARIABLE '=' static_scalar
    ;

    

optional_class_type
    : 
    | T_ARRAY
    | T_CALLABLE
    | fully_qualified_class_name  // 其实这个结构就是一个带或不带命名空间的类名
    ;
    
fully_qualified_class_name
    : namespace_name
    | T_NAMESPACE T_NS_SEPARATOR namespace_name
    | T_NS_SEPARATOR namespace_name
    ;

static_scalar
    : comment_scalar
    | namespace_name
    | T_NAMESPACE T_NS_SEPARATOR namespace_name
    | T_NS_SEPARATOR namespace_name
    | '+' static_scalar
    | '-' static_scalar
    | T_ARRAY '(' static_array_pair_list ')'
    | '[' static_array_pair_list ']'
    | static_class_constant
    | T_CLASS_C 
    ;


common_scalar
    : T_LNUMBER
    | T_DNUMBER
    | T_CONSTANT_ENCAPSED_STRING
    | T_LINE
    | T_FILE
    | T_DIR
    | T_TRAIT_C
    | T_METHOD_C
    | T_FUNC_C
    | T_NS_C
    | T_START_HEREDOC T_ENCAPSED_AND_WHITESPACE T_END_HEREDOC
    | T_START_HEREDOC T_END_HEREDOC
    ;

use_declarations
    : use_declarations ',' use_declaration
    | use_declaration
    ;
use_declaration
    : namespace_name
    | namespace_name T_AS T_STRING  // demo as demo1
    | T_NS_SEPARATOR namespace_name
    | T_NS_SEPARATOR namespace_name T_AS T_STRING
    ;

constant_declaration
    : constant_declaration ',' T_STRING '=' static_scalar // consot DEMO = 100, FUCK = 200
    | T_CONST T_STRING '=' static_scalar // const DEMO = 100
    ;

