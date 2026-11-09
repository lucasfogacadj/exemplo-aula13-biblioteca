using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<BibliotecaDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Biblioteca")
        ?? "Data Source=biblioteca.db"));

var app = builder.Build();

// Mantém a resposta pública genérica; detalhes técnicos não são enviados ao cliente.
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new
        {
            mensagem = "Ocorreu um erro interno. Tente novamente mais tarde."
        });
    });
});

app.UseDefaultFiles();
app.UseStaticFiles();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<BibliotecaDbContext>();
    await db.Database.EnsureCreatedAsync();
}

app.MapGet("/api/livros", async (BibliotecaDbContext db) =>
    Results.Ok(await db.Livros.OrderBy(livro => livro.Id).ToListAsync()));

app.MapGet("/api/livros/{id:int}", async (int id, BibliotecaDbContext db) =>
{
    var livro = await db.Livros.FindAsync(id);
    return livro is null ? Results.NotFound() : Results.Ok(livro);
});

app.MapPost("/api/livros", async (LivroEntrada entrada, BibliotecaDbContext db) =>
{
    var livro = new Livro
    {
        Titulo = entrada.Titulo,
        Autor = entrada.Autor,
        AnoPublicacao = entrada.AnoPublicacao
    };

    db.Livros.Add(livro);
    await db.SaveChangesAsync();
    return Results.Created($"/api/livros/{livro.Id}", livro);
});

app.MapPut("/api/livros/{id:int}", async (int id, LivroEntrada entrada, BibliotecaDbContext db) =>
{
    var livro = await db.Livros.FindAsync(id);
    if (livro is null)
    {
        return Results.NotFound();
    }

    livro.Titulo = entrada.Titulo;
    livro.Autor = entrada.Autor;
    livro.AnoPublicacao = entrada.AnoPublicacao;
    await db.SaveChangesAsync();
    return Results.Ok(livro);
});

app.MapDelete("/api/livros/{id:int}", async (int id, BibliotecaDbContext db) =>
{
    var livro = await db.Livros.FindAsync(id);
    if (livro is null)
    {
        return Results.NotFound();
    }

    db.Livros.Remove(livro);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

// Rota isolada para o smoke test da CI; não é registrada nos ambientes normais.
if (app.Environment.IsEnvironment("SmokeTest"))
{
    app.MapGet("/api/teste-erro", () =>
    {
        throw new InvalidOperationException("Falha simulada para teste.");
    });
}

app.Run();

sealed class BibliotecaDbContext(DbContextOptions<BibliotecaDbContext> options)
    : DbContext(options)
{
    public DbSet<Livro> Livros => Set<Livro>();
}

sealed class Livro
{
    public int Id { get; set; }
    public string Titulo { get; set; } = "";
    public string Autor { get; set; } = "";
    public int AnoPublicacao { get; set; }
}

sealed record LivroEntrada(string Titulo, string Autor, int AnoPublicacao);
