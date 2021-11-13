using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.SqlServer;
using Babelfish_Testbed.Models;

var builder = WebApplication.CreateBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("ToDoDatabase");
builder.Services.AddDbContext<TodoContext>( opt => opt.UseSqlServer(connectionString));
var app = builder.Build();

app.MapGet("/", () => "Hello World!");

app.MapGet("/todoitems", async (TodoContext db) =>
    await db.Todos.ToListAsync());

app.MapGet("/todoitems/complete", async (TodoContext db) =>
    await db.Todos.Where(t => t.IsComplete).ToListAsync());

app.MapGet("/todoitems/incomplete", async (TodoContext db) =>
    await db.Todos.Where(t => t.IsComplete == false).ToListAsync());

app.MapGet("/todoitems/{id}", async (int id, TodoContext db) =>
    await db.Todos.FindAsync(id)
        is Todo todo
            ? Results.Ok(todo)
            : Results.NotFound());

app.MapPost("/todoitems", async (Todo todo, TodoContext db) =>
{
    db.Todos.Add(todo);
    await db.SaveChangesAsync();

    return Results.Created($"/todoitems/{todo.Id}", todo);
});

app.MapPut("/todoitems/{id}", async (int id, Todo inputTodo, TodoContext db) =>
{
    var todo = await db.Todos.FindAsync(id);

    if (todo is null) return Results.NotFound();

    todo.Name = inputTodo.Name;
    todo.IsComplete = inputTodo.IsComplete;

    await db.SaveChangesAsync();

    return Results.NoContent();
});

app.MapDelete("/todoitems/{id}", async (int id, TodoContext db) =>
{
    if (await db.Todos.FindAsync(id) is Todo todo)
    {
        db.Todos.Remove(todo);
        await db.SaveChangesAsync();
        return Results.Ok(todo);
    }

    return Results.NotFound();
});

app.Run();
