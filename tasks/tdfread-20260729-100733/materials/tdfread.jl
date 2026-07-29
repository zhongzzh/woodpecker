using TyStatisticsCore
using Test

function _tdfread_from_string(content, delimiter="tab"; toworkspace=Val(false))
    return mktemp() do filename, io
        write(io, content)
        close(io)
        return tdfread(filename, delimiter; toworkspace=toworkspace)
    end
end

const TDFREAD_DELIMITERS = (
    (name="space", character=(' ')),
    (name="tab", character=('\t')),
    (name="comma", character=(',')),
    (name="semi", character=(';')),
    (name="bar", character=('|')),
)

@testset "tdfread: delimiter 与字符串列" begin
    for delimiter in TDFREAD_DELIMITERS
        aliases = Any[
            delimiter.name,
            Symbol(delimiter.name),
            delimiter.character,
            string(delimiter.character),
        ]
        delimiter.name == "tab" && push!(aliases, "\\t")

        separator = string(delimiter.character)
        content = join(
            (
                "Name$(separator)Score$(separator)Note",
                "Alice$(separator)1.5$(separator)first",
                "Bob$(separator)missing$(separator)second",
            ),
            "\n",
        )
        for alias in aliases
            result = _tdfread_from_string(content, alias)
            @test result.Name == ["Alice", "Bob"]
            @test result.Score == ["1.5", "missing"]
            @test result.Note == ["first", "second"]
            @test result.Name isa Vector{String}
            @test result.Score isa Vector{String}
            @test result.Note isa Vector{String}
        end
    end

    result = _tdfread_from_string("A\tB\n1\t2\n")
    @test result == (A=[1.0], B=[2.0])

    # MATLAB tdfread collapses each internal whitespace run to its last character
    # when the delimiter is neither tab nor space.
    result = _tdfread_from_string("Text,Num\na  b,1\nc\t\td,2\n", "comma")
    @test result.Text == ["a b", "c\td"]
    @test result.Num == [1.0, 2.0]
end

@testset "tdfread: toworkspace 到 Main" begin
    @test !isdefined(Main, :TdfreadExportedName)
    @test !isdefined(Main, :TdfreadExportedValue)

    result, summary_text = mktemp() do _, output
        result = redirect_stdout(output) do
            mktemp() do filename, io
                write(io, "TdfreadExportedName,TdfreadExportedValue\nAlice,42\nBob,7\n")
                close(io)
                tdfread(filename, "comma")
            end
        end
        flush(output)
        seekstart(output)
        return result, read(output, String)
    end
    @test result === nothing
    @test Main.TdfreadExportedName == ["Alice", "Bob"]
    @test Main.TdfreadExportedValue == [42.0, 7.0]

    @test occursin("Name", summary_text)
    @test occursin("Size", summary_text)
    @test occursin("Bytes", summary_text)
    @test occursin("Type", summary_text)
    @test occursin("TdfreadExportedName", summary_text)
    @test occursin("(2,)", summary_text)
    @test occursin(string(Base.summarysize(Main.TdfreadExportedName)), summary_text)
    @test occursin("Vector{String}", summary_text)
    @test occursin("TdfreadExportedValue", summary_text)
    @test occursin(string(sizeof(Main.TdfreadExportedValue)), summary_text)
    @test occursin("Vector{Float64}", summary_text)
    @test first(findfirst("TdfreadExportedName", summary_text)) <
        first(findfirst("TdfreadExportedValue", summary_text))

    @test !isdefined(Main, :TdfreadNotExported)
    result = _tdfread_from_string("TdfreadNotExported\nvalue\n")
    @test result.TdfreadNotExported == ["value"]
    @test !isdefined(Main, :TdfreadNotExported)

    @test !isdefined(Main, :TdfreadGoodAfterFailure)
    result, summary_text = mktemp() do _, output
        result = @test_logs (:warn, "Could not create variable Base in the workspace.") redirect_stdout(
            output
        ) do
            _tdfread_from_string(
                "Base,TdfreadGoodAfterFailure\nblocked,1\n",
                "comma";
                toworkspace=Val(true),
            )
        end
        flush(output)
        seekstart(output)
        return result, read(output, String)
    end
    @test result === nothing
    @test Main.TdfreadGoodAfterFailure == [1.0]
    @test !occursin("Base", summary_text)
    @test occursin("TdfreadGoodAfterFailure", summary_text)

    result, summary_text = mktemp() do _, output
        result = redirect_stdout(output) do
            _tdfread_from_string(""; toworkspace=Val(true))
        end
        flush(output)
        seekstart(output)
        return result, read(output, String)
    end
    @test result === nothing
    @test isempty(summary_text)

    tdf_module = parentmodule(tdfread)
    rpad = getfield(tdf_module, :_tdf_rpad)
    lpad = getfield(tdf_module, :_tdf_lpad)
    @test rpad("long", 2) == "long"
    @test lpad("long", 2) == "long"
    @test rpad("x", 3) == "x  "
    @test lpad("x", 3) == "  x"
end

@testset "tdfread: 表头、空字段与换行" begin
    result = _tdfread_from_string("\r\n,A B,,A B,a-b\r1,,3,x\r\r2,4,,y\r", "comma")
    @test propertynames(result) == (:A_B, :Var2, :A_B1, :a_b)
    @test result.A_B == [1.0, 2.0]
    @test isnan(result.Var2[1]) && result.Var2[2] == 4.0
    @test result.A_B1[1] == 3.0 && isnan(result.A_B1[2])
    @test result.a_b == ["x", "y"]

    result = _tdfread_from_string("A,A,A1,A\n1,2,3,4\n", "comma")
    @test propertynames(result) == (:A, :A2, :A1, :A3)

    result = _tdfread_from_string(
        "if,export,1A,中文,name!\ncondition,value,number,text,mutating\n", "comma"
    )
    @test propertynames(result) == (:xIf, :xExport, :x_1A, :中文, :name!)
    @test result.xIf == ["condition"]
    @test result.xExport == ["value"]
    @test result.x_1A == ["number"]
    @test result.中文 == ["text"]
    @test getproperty(result, :name!) == ["mutating"]

    result = _tdfread_from_string("  First  Name \t Value \n New  York \t 10 \n")
    @test propertynames(result) == (:First_Name, :Value)
    @test result.First_Name == ["New York"]
    @test result.Value == [10.0]

    result = _tdfread_from_string("A,B\n", "comma")
    @test result.A == String[]
    @test result.B == String[]

    # A line containing exactly one delimiter is an all-empty observation in MATLAB.
    for delimiter in TDFREAD_DELIMITERS
        separator = string(delimiter.character)
        result = _tdfread_from_string(
            "A$(separator)B\n$(separator)\n1$(separator)2\n", delimiter.name
        )
        @test isequal(result.A, [NaN, 1.0])
        @test isequal(result.B, [NaN, 2.0])

        @test_throws ArgumentError _tdfread_from_string(
            "A$(separator)B\n$(separator)$(separator)\n1$(separator)2\n", delimiter.name
        )
    end

    result = _tdfread_from_string("---,a-b,a_b\none,two,three\n", "comma")
    @test propertynames(result) == (:x, :a_b, :a_b1)
    @test result.x == ["one"]
end

@testset "tdfread: 可计算列" begin
    result = _tdfread_from_string(
        "Trig,Arithmetic,WithEmpty,Complex,Unsafe,AllEmpty\n" *
        "sin(1),1+2,,1+2im,open(\"file\"),\n" *
        "cos(1),sqrt(16),4,2-3im,run(`echo unsafe`),\n",
        "comma",
    )

    @test result.Trig ≈ [sin(1), cos(1)]
    @test result.Arithmetic == [3.0, 4.0]
    @test isnan(result.WithEmpty[1]) && result.WithEmpty[2] == 4.0
    @test result.Complex == ComplexF64[1 + 2im, 2 - 3im]
    @test result.Unsafe == ["open(\"file\")", "run(`echo unsafe`)"]
    @test all(isnan, result.AllEmpty)

    result = _tdfread_from_string(
        "Constants\tUnary\tAngles\tParts\tDynamic\tConstructor\tUnknown\tVectorExpr\tQualifiedCall\tLiteral\n" *
        "pi\t-2\tsind(30)\treal(1+2im)\tgcd(12,8)\tFloat64(2)\tunknown\t[1]\tBase.sin(1)\t\"text\"\n" *
        "Inf\t+3\tcosd(60)\timag(1+2im)\tlcm(3,4)\tInt8(3)\tother\t[2]\tBase.cos(1)\t\"more\"\n",
    )
    @test result.Constants[1] == Float64(pi) && isinf(result.Constants[2])
    @test result.Unary == [-2.0, 3.0]
    @test result.Angles ≈ [0.5, 0.5]
    @test result.Parts == [1.0, 2.0]
    @test result.Dynamic == [4.0, 12.0]
    @test result.Constructor == [2.0, 3.0]
    @test result.Unknown == ["unknown", "other"]
    @test result.VectorExpr == ["[1]", "[2]"]
    @test result.QualifiedCall == ["Base.sin(1)", "Base.cos(1)"]
    @test result.Literal == ["\"text\"", "\"more\""]

    result = _tdfread_from_string("ComplexEmpty,Label\n,a\n1+2im,b\n", "comma")
    @test isnan(real(result.ComplexEmpty[1]))
    @test result.ComplexEmpty[2] == 1 + 2im
    @test result.Label == ["a", "b"]

    result = _tdfread_from_string(
        "Integer,LeadingZero,SignedZero\n1,01,-0\n-2,002,+0\n", "comma"
    )
    @test result.Integer == [1.0, -2.0]
    @test result.LeadingZero == [1.0, 2.0]
    @test result.SignedZero == [0.0, 0.0]
end

@testset "tdfread: 空文件、delimiter 回退与报错" begin
    result = _tdfread_from_string("")
    @test result == NamedTuple()

    result = _tdfread_from_string("A\tB\n1\t2\n", "")
    @test result == (A=[1.0], B=[2.0])

    result = @test_logs (:warn, "Using non-standard delimiter: ':'.") _tdfread_from_string(
        "A:B\n1:2\n", "::"
    )
    @test result == (A=[1.0], B=[2.0])

    @test_throws ArgumentError("Line 2 has 1 fields, expected 2.") _tdfread_from_string(
        "A,B\n1\n", "comma"
    )
    @test_throws TypeError _tdfread_from_string("A\n1\n"; toworkspace=false)
    @test_throws ArgumentError("The delimiter cannot be empty.") _tdfread_from_string(
        "A\n1\n", Symbol("")
    )

    mktemp() do filename, io
        write(io, "A\n1\n")
        close(io)
        @test_throws MethodError tdfread(filename; bad=Val(false))
    end
end
