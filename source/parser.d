/**
 * A parser for the "Delight" programming language.
 * Author: Peter Plantinga
 *
 * This "Delightful" parser
 * - is initialized with a string
 *   containing the name of the source code file
 * - breaks code into tokens with a lexer
 * - checks for syntax errors in the source code
 * - generates valid d code
 */
import lexer;
import std.algorithm;
import std.conv;
import std.stdio;
import std.range;
import std.array;
import std.file;

class parser
{
	/** Breaks source code into tokens */
	lexer l;

	/** These give a new value to a variable */
	static immutable string[] assignment_operators = [
		"=",
		"+=",
		"-=",
		"*=",
		"/=",
		"%=",
		"~=",
		"^="
	];
	
	/** These are used when declaring things. */
	static immutable string[] attributes = [
		"abstract",
		"const",
		"static immutable",
		"in",
		"inout",
		"lazy",
		"nothrow",
		"out",
		"override",
		"pure",
		"ref",
		"shared",
		"static",
		"synchronized"
	];

	/** Compare and contrast, producing booleans. */
	static immutable string[] logical = [
		"and",
		"equals",
		"is",
		"less than",
		"more than",
		"not",
		"or"
	];

	/** All about combining literals and variables creating expressions. */
	static immutable string[] operators = [
		"+",
		"-",
		"*",
		"/",
		"%",
		"~",
		"^"
	];

	/** These do weird stuff. */
	static immutable string[] punctuation = [
		",",
		".",
		":",
		"(",
		")",
		"[",
		"]",
		"\"",
		"'",
		"#",
		"->"
	];

	/** These do things. */
	static immutable string[] statements = [
		"assert",
		"break",
		"catch",
		"continue",
		"do",
		"finally",
		"foreach",
		"foreach_reverse",
		"import",
		"mixin",
		"return",
		"switch",
		"throw",
		"try",
		"typeof"
		"while"
	];

	/** How is stuff stored in memory? */
	static immutable string[] types = [
		"auto", "bool", "void", "string",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	];

	/** More complicated types. */
	static immutable string[] user_types = [
		"alias",
		"class",
		"enum",
		"struct",
		"union"
	];

	/** Initialize with a string containing location of source code. */
	this( string filename )
	{
		/** Lexer parses source into tokens */
		l = new lexer( filename );
	}

	/** What kind of thing is this token? */
	string identify_token( string token )
	{
		if ( count( [
					" ",
					"\n",
					"indentation 1",
					"indentation -1"
					], token ) )
			return token;
		else if ( count( assignment_operators, token ) )
			return "assignment operator";
		else if ( count( attributes, token ) )
			return "attribute";
		else if ( count( logical, token ) )
			return "logical";
		else if ( count( operators, token ) )
			return "operator";
		else if ( count( punctuation, token ) )
			return "punctuation";
		else if ( count( statements, token ) )
			return "statement";
		else if ( count( types, token ) )
			return "type";
		else if ( count( user_types, token ) )
			return "user type";
		else
			return "identifier";
	}
	unittest
	{
		parser p = new parser( "tests/test1.delight" );
		assert( p.identify_token( "=" ) == "assignment operator" );
		assert( p.identify_token( "+=" ) == "assignment operator" );
		assert( p.identify_token( "%=" ) == "assignment operator" );
		assert( p.identify_token( "~=" ) == "assignment operator" );
		assert( p.identify_token( "pure" ) == "attribute" );
		assert( p.identify_token( "and" ) == "logical" );
		assert( p.identify_token( "less than" ) == "logical" );
		assert( p.identify_token( "-" ) == "operator" );
		assert( p.identify_token( "^" ) == "operator" );
		assert( p.identify_token( "." ) == "punctuation" );
		assert( p.identify_token( ":" ) == "punctuation" );
		assert( p.identify_token( "foreach" ) == "statement" );
		assert( p.identify_token( "try" ) == "statement" );
		assert( p.identify_token( "char" ) == "type" );
		assert( p.identify_token( "string" ) == "type" );
		assert( p.identify_token( "int" ) == "type" );
		assert( p.identify_token( "long" ) == "type" );
		assert( p.identify_token( "class" ) == "user type" );
		assert( p.identify_token( "asdf" ) == "identifier" );
	}
	
	string parse()
	{
		string result;

		while ( !l.is_empty() )
		{
			try
			{
				result ~= start_state( l.pop() );
			}
			catch ( Exception e )
			{
				writeln( e.msg );
				return result;
			}
		}

		return result;
	}
	unittest
	{
		parser p1 = new parser( "tests/test1.delight" );
		assert( p1.parse() == "import std.stdio;\n" );

		parser p2 = new parser( "tests/test2.delight" );
		assert( p2.parse() == "void main()\n\t{\n\tint x = 5;\n}\n" );

		parser p3 = new parser( "tests/test3.delight" );
		assert( p3.parse() == "import std.stdio;\n\nvoid main()\n\t{\n\tstring greeting = \"Hello\";\n\tgreeting ~= \", world!\";\n\twriteln(greeting);\n}\n" );
	}

	/** The starting state for the parser */
	string start_state( string token )
	{
		string indent = join( repeat( l.indentation, l.indentation_level ) );
		switch ( identify_token( token ) )
		{
			case "statement":
				if ( token == "import" )
					return token ~ " " ~ im_state( l.pop() );
				else
					throw unexpected( token );
			case "type":
				return token ~ " " ~ declare_state( l.pop() );
			case "\n":
				return token ~ indent;
			case "identifier":
				return token ~ identifier_state( l.pop() );
			case "indentation 1":
				return "{\n" ~ indent;
			case "indentation -1":
				return "}\n" ~ indent;
			default:
				throw unexpected( token );
		}
	}

	string im_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ library_state( l.pop() );
			default:
				throw unexpected( token );
		}
	};

	string library_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "punctuation":
				if ( token == "." )
					return token ~ period_state( l.pop() );
				else
					throw unexpected( token );
			case "\n":
				return ";" ~ endline();
			default:
				throw unexpected( token );
		}
	}

	string period_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ library_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string declare_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ declared_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string declared_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "punctuation":
				if ( token == "(" )
					return token ~ function_declaration_state( l.pop() );
				else if ( token == "," )
					return token ~ declare_state( l.pop() );
				else
					throw unexpected( token );
			case "assignment operator":
				return " " ~ token ~ " " ~ expression_state( l.pop() );
			case "\n":
				return ";" ~ endline();
			default:
				throw unexpected( token );
		}
	}

	string function_declaration_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "type":
				return token ~ function_variable_state( l.pop() );
			case "punctuation":
				if ( token == ")" )
					return token ~ colon_state( l.pop() );
				else
					throw unexpected( token );
			default:
				throw unexpected( token );
		}
	}

	string function_variable_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ function_declaration_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string colon_state( string token )
	{
		if ( token == ":" && l.pop() == "\n" )
			return endline();
		else
			throw new Exception( "On line " ~ to!string( l.line_number ) ~ " expected ':\\n'" );
	}

	string identifier_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "punctuation":
				if ( token == "(" )
					return token ~ function_call_state( l.pop() );
				else
					throw unexpected( token );
			case "assignment operator":
				return " " ~ token ~ " " ~ expression_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string function_call_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ function_call_state( l.pop() );
			case "punctuation":
				if ( token == ")" )
					return token ~ endline_state( l.pop() );
				else
					throw unexpected( token );
			default:
				throw unexpected( token );
		}
	}

	string expression_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "identifier":
				return token ~ endline_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string endline_state( string token )
	{
		if ( token == "\n" )
			return ";" ~ endline();
		else
			throw unexpected( token );
	}

	/**
	 * New line, plus indentation
	 */
	string endline()
	{
		return "\n" ~ join( repeat( l.indentation, l.indentation_level ) );
	}

	/**
	 * We didn't expect to find this kind of token!
	 * so generate an exception.
	 */
	Exception unexpected( string token )
	{
		return new Exception( "On line " ~ to!string( l.line_number ) ~ ": unexpected " ~ identify_token( token ) ~ " '" ~ token ~ "'" );
	}
}
