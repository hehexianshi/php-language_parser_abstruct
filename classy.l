%s ST_IN_SCRIPTING
LNUM [0-9]+
DNUM ([0-9]*"."[0-9]+)|([0-9]+"."[0-9]*)
EXPONENT_DNUM (({LNUM}|{DNUM})[eE][+-]?{LNUM})
HNUM "0x"[0-9a-fA-F]+
BUNM "0b"[01]+
LABEL [a-zA-Z_\0x7f-\0xff][a-zA-Z0-9_\0x7f-\0xff]*
WHITESPACE [ \n\r\t]+
TABS_AND_SPACES [ \t]*
TOKENS [;:,.\[\]()|^&+-/*=%!~$<>?@]
ANY_CHAR [^]
NEWLINE ("\r"|"\n"|"\r\n")
 
%%
"//".*                      /* ignore comment */
<INITIAL>"<?php"                     { this.pushState('ST_IN_SCRIPTING'); return 'PHPSTART';}
<ST_IN_SCRIPTING>"exit" {
    return 'T_EXIT';
}

<ST_IN_SCRIPTING>"dir" {
    return 'T_EXIT';
}

<ST_IN_SCRIPTING>"function" {
    return 'T_FUNCTION';
}

<ST_IN_SCRIPTING>"const" {
    return 'T_CONST';
}

<ST_IN_SCRIPTING>"return" {
    return 'T_RETURN';
}

<ST_IN_SCRIPTING>"try" {
    return 'T_TRY';
}

<ST_IN_SCRIPTING>"catch" {
    return 'T_CATCH';
}

<ST_IN_SCRIPTING>"throw" {
    return 'T_THROW';
}

<ST_IN_SCRIPTING>"if" {
    return 'T_IF';
}

<ST_IN_SCRIPTING>"elseif" {
    return 'T_ELSEIF';
}

<ST_IN_SCRIPTING>"endif" {
    return 'T_ENDIF';
}

<ST_IN_SCRIPTING>"else" {
    return 'T_ELSE';
}

<ST_IN_SCRIPTING>"while" {
    return 'T_WHILE';
}

<ST_IN_SCRIPTING>"endwhile" {
    return 'T_ENDWHILE';
}

<ST_IN_SCRIPTING>"do" {
    return 'T_DO';
}

<ST_IN_SCRIPTING>"for" {
    return 'T_FOR';
}

<ST_IN_SCRIPTING>"endfor" {
    return 'T_ENDFOR';
}

<ST_IN_SCRIPTING>"foreach" {
    return 'T_FOREACH';
}

<ST_IN_SCRIPTING>"endforeach" {
    return 'T_ENDFOREACH';
}

<ST_IN_SCRIPTING>"declare" {
    return 'T_DECLARE';
}

<ST_IN_SCRIPTING>"enddeclare" {
    return 'T_ENDDECLARE';
}

<ST_IN_SCRIPTING>"instanceof" {
    return 'T_INSTANCEOF';
}

<ST_IN_SCRIPTING>"as" {
    return 'T_AS';
}

<ST_IN_SCRIPTING>"switch" {
    return 'T_SWITCH';
}

<ST_IN_SCRIPTING>"endswitch" {
    return 'T_ENDSWITCH';
}

<ST_IN_SCRIPTING>"case" {
    return 'T_CASE';
}

<ST_IN_SCRIPTING>"default" {
    return 'T_DEFAULT';
}

<ST_IN_SCRIPTING>"break" {
    return 'T_BREAK';
}

<ST_IN_SCRIPTING>"continue" {
    return 'T_CONTINUE';
}

<ST_IN_SCRIPTING>"goto" {
    return 'T_GOTO';
}

<ST_IN_SCRIPTING>"echo" {
    return 'T_ECHO';
}

<ST_IN_SCRIPTING>"print" {
    return 'T_PRINT';
}

<ST_IN_SCRIPTING>"class" {
    return 'T_CLASS';
}

<ST_IN_SCRIPTING>"interface" {
    return 'T_INTERFACE';
}

<ST_IN_SCRIPTING>"trait" {
    return 'T_TRAIT';
}

<ST_IN_SCRIPTING>"extends" {
    return 'T_EXTENDS';
}

<ST_IN_SCRIPTING>"implements" {
    return 'T_IMPLEMENTS';
}

<ST_IN_SCRIPTING>"->" {
    this.pushState('ST_LOOKING_FOR_PROPERTY');
    return 'T_OBJECT_OPERATOR';
}

<ST_IN_SCRIPTING,ST_LOOKING_FOR_PROPERTY>{WHITESPACE}+ {
    return T_WHITESPACE;
}

<ST_LOOKING_FOR_PROPERTY>"->" {
    return 'T_OBJECT_OPERATOR';
}

<ST_IN_SCRIPTING,ST_VAR_OFFSET>{LABEL} {
    this.popState();
    return T_STRING;
}

<ST_IN_SCRIPTING>"::" {
    return T_PAAMAYIM_NEKUDOTAYIM;
}

<ST_IN_SCRIPTING>"\\" {
    return T_NS_SEPARATOR;
}

<ST_IN_SCRIPTING>"new" {
    return T_NEW;
}

<ST_IN_SCRIPTING>"clone" {
    return T_CLONE;
}

<ST_IN_SCRIPTING>"var" {
    return T_VAR;
}

<ST_IN_SCRIPTING>"("{TABS_AND_SPACES}("int"|"integer"){TABS_AND_SPACES}")" {
    return T_INT_CAST;
}

<ST_IN_SCRIPTING>"namespace" {
    return T_NAMESPACE;
}

<ST_DOUBLE_QUOTES,ST_HEREDOC,ST_BACKQUOTE>"$"{LABEL}"->"[a-zA-Z_\x7f-\xff] {
    this.pushState('ST_LOOKING_FOR_PROPERTY');
    return T_VARIABLE;
}

<ST_DOUBLE_QUOTES,ST_HEREDOC,ST_BACKQUOTE>"$"{LABEL}"[" {
    // 这种形式 为字符串内数组变量
    this.pushState('ST_VAR_OFFSET');
    return T_VARIABLE;
}

<ST_IN_SCRIPTING,ST_DOUBLE_QUOTES,ST_HEREDOC,ST_BACKQUOTE,ST_VAR_OFFSET>"$"{LABEL} {
    return T_VARIABLE;
}

<ST_VAR_OFFSET>"]" {
    // 退出[]模式 
    this.popState();
    return ']';
}

<ST_VAR_OFFSET>[ \n\r\t\\'#] {
    this.popState();
    return T_ENCAPSED_AND_WHITESPACE;
}

<ST_IN_SCRIPTING>"__halt_compiler" {
    return T_HALT_COMPILER
}

<ST_IN_SCRIPTING>"array" {
    return T_ARRAY
}

<ST_IN_SCRIPTING>"callable" {
    return T_CALLABLE
}

<ST_IN_SCRIPTING>b?"<<<"{TABS_AND_SPACES}({LABEL}|([']{LABEL}['])|(["]{LABEL}["])){NEWLINE} {

    // b? 会转成 \b?
    // 实际上php 代码里面处理了但是与返回标签没有联系 只是对内容的长度和字符截取
    // 其中根据一些条件 激活开始条件
    // 类似 BEGIN(ST_HEREDOC);

    return T_START_HEREDOC
}

<ST_END_HEREDOC>{ANY_CHAR} {
    // 上面的 会有机会使用ST_END_HEREDOC
    // 例如 end == '\n' or end == '\r' begin(ST_END_HEREDOC)
    // jison 里面可以使用 this.begin('ST_END_HEREDOC')
    return T_END_HEREDOC
}

<ST_DOUBLE_QUOTES>{ANY_CHAR} {

    // php 里面有 GET_DOUBLE_QUOTES_SCANNED_LENGTH() 这个方法  使用了 CG(doc_comment_len)
    // 就说说 获取doc_commet的长度 如果有长度 就直接返回

    return T_ENCAPSED_AND_WHITESPACE;

    // 后面的要做一些其他的字符处理  主要是游标的一些处理 ++ -- 之类的

}

<ST_IN_SCRIPTING>"__NAMESPACE__" {
    // php 有些其他操作 这里只说语法
    return T_NS_C; 
}

<ST_IN_SCRIPTING>"__FUNCTION__" {

    return T_FUNC_C;
}

<ST_IN_SCRIPTING>"__METHOD__" {
    
    return T_METHOD_C;
}

<ST_IN_SCRIPTING>"__TARIT__" {

    return T_TRAIT_C;
}

<ST_IN_SCRIPTING>"__DIR__" {

    return T_DIR;
}

<ST_IN_SCRIPTING>"__FILE__" {

    return T_FILE;
}

<ST_IN_SCRIPTING>"__LINE__" {
    
    return T_LINE;
}

<ST_IN_SCRIPTING>b?['] {
    
}

<ST_IN_SCRIPTING>b?["] {
    // 由于jison没有办法使用类似c的字符串数组指针++ 所以写语法结构的时候就得把字符串匹配整体写出来
    if(this.next() == '"')
        return T_CONSTANT_ENCAPSED_STRING;

    else
        return '"';

}

<ST_IN_SCRIPTING>{BNUM} {
    len = yyleng - 2;
    yytext = yytext.substr(2, yyleng);

    // 下面sizeof_long 是c里面的
    // 如果长度过长 就得换类型了
    // 还有HNUM 能返回下面两种类型 就不写了
    if(len < SIZEOF_LONG * 8)
        return T_LNUMBER;
    else
        return T_DNUMBER;
}

<ST_LOOKING_FOR_VARNAME>{LABEL} {

    return T_STRING_VARNAME;
}

<ST_DOUBLE_QUOTES,ST_BACKQUOTE,ST_HEREDOC>"${" {
    
    return T_DOLLAR_OPEN_CURLY_BRACES; 
}

<ST_DOUBLE_QUOTES,ST_BACKQUOTE,ST_HEREDOC>"{$" {

    return T_CURLY_OPEN;
}

<ST_IN_SCRIPTING>"isset" {
    
    return T_ISSET;
}

<ST_IN_SCRIPTING>"empty" {

    return T_EMPTY
}

<ST_IN_SCRIPTING>"include" {
    
    return T_INCLUDE;
}

<ST_IN_SCRIPTING>"include_once" {

    return T_INCLUDE_ONCE;
}

<ST_IN_SCRIPTING>"eval" {

    return T_EVAL:
}

<ST_IN_SCRIPTING>"require" {

    return T_REQUIRE;
}

<ST_IN_SCRIPTING>"require_once" {

    return T_REQUIRE_ONCE;
}

<ST_IN_SCRIPTING>"=>" {
    
    return T_DOUBLE_ARROWg
}
<ST_IN_SCRIPTING>"use" {
    return T_USE;
}

<ST_IN_SCRIPTING>"++" {
        return T_INC;
}
 
<ST_IN_SCRIPTING>"--" {
        return T_DEC;
}
           
<ST_IN_SCRIPTING>"===" {
        return T_IS_IDENTICAL;
}
           
<ST_IN_SCRIPTING>"!==" {
        return T_IS_NOT_IDENTICAL;
}
                                                                                                                                                                                         
<ST_IN_SCRIPTING>"==" {
        return T_IS_EQUAL;
}          
 
<ST_IN_SCRIPTING>"!="|"<>" {
        return T_IS_NOT_EQUAL;
}          
 
<ST_IN_SCRIPTING>"<=" {
        return T_IS_SMALLER_OR_EQUAL;
}          
 
<ST_IN_SCRIPTING>">=" {
        return T_IS_GREATER_OR_EQUAL;
}          
 
<ST_IN_SCRIPTING>"+=" {
        return T_PLUS_EQUAL;
}
 
<ST_IN_SCRIPTING>"-=" {
        return T_MINUS_EQUAL;
}
 
<ST_IN_SCRIPTING>"*=" {
        return T_MUL_EQUAL;
}

<ST_IN_SCRIPTING>"/=" {
        return T_DIV_EQUAL;
}           
            
<ST_IN_SCRIPTING>".=" {
        return T_CONCAT_EQUAL;
}           
            
<ST_IN_SCRIPTING>"%=" {
        return T_MOD_EQUAL;
}           
            
<ST_IN_SCRIPTING>"<<=" {
        return T_SL_EQUAL;                                                                                                                                                                   
}           
            
<ST_IN_SCRIPTING>">>=" {
        return T_SR_EQUAL;
}           
            
<ST_IN_SCRIPTING>"&=" {
        return T_AND_EQUAL;
}           
            
<ST_IN_SCRIPTING>"|=" {
        return T_OR_EQUAL;
}           
            
<ST_IN_SCRIPTING>"^=" {
        return T_XOR_EQUAL;
}          
<ST_IN_SCRIPTING>"||" {
        return T_BOOLEAN_OR;
}
 
<ST_IN_SCRIPTING>"&&" {
        return T_BOOLEAN_AND;
}

<ST_IN_SCRIPTING>"OR" {
        return T_LOGICAL_OR;
}
                                                                                                                                                                                         
<ST_IN_SCRIPTING>"AND" {
        return T_LOGICAL_AND;
}
 
<ST_IN_SCRIPTING>"XOR" {
        return T_LOGICAL_XOR;
}
 
<ST_IN_SCRIPTING>"<<" {
        return T_SL;
}
 
<ST_IN_SCRIPTING>">>" {
        return T_SR;
}
<ST_IN_SCRIPTING>{TOKENS} {
    return this.yytext()[0];
}

<INITIAL>"<script"{WHITESPACE}+"language"{WHITESPACE}*"="{WHITESPACE}*("php"|"\"php\""|"'php'"){WHITESPACE}*">" {


    return T_OPEN_TAG;
}

<INITIAL>"<%=" {

    // 如果开启了 asp_tags
    return T_OPEN_TAG_WITH_ECHO;


}
