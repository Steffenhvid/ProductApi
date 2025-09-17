using Microsoft.AspNetCore.Mvc;
using ProductsApi.Models;

namespace ProductsApi.Controllers
{
    /// <summary>
    /// Controller responsible for product CRUD operations.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private static readonly List<Product> _products = new()
        {
            new Product { Id = Guid.NewGuid(), Name = "Widget A", Description = "Basic widget", Price = 9.99m, Quantity = 100 },
            new Product { Id = Guid.NewGuid(), Name = "Widget B", Description = "Advanced widget", Price = 19.99m, Quantity = 50 },
            new Product { Id = Guid.NewGuid(), Name = "Gadget", Description = "Multi-purpose gadget", Price = 29.99m, Quantity = 25 }
        };

        /// <summary>
        /// Get a product by its id.
        /// </summary>
        /// <param name="id">Product id.</param>
        /// <returns>The product if found; 404 otherwise.</returns>
        [HttpGet("{id:guid}")]
        public ActionResult<Product> GetById(Guid id)
        {
            var product = _products.FirstOrDefault(p => p.Id == id);
            if (product == null) return NotFound();
            return Ok(product);
        }

        /// <summary>
        /// Get products by query.
        /// </summary>
        /// <param name="name">Optional name contains filter.</param>
        /// <param name="minPrice">Optional minimum price.</param>
        /// <param name="maxPrice">Optional maximum price.</param>
        /// <returns>List of matching products.</returns>
        [HttpGet]
        public ActionResult<IEnumerable<Product>> GetByQuery([FromQuery] string? name, [FromQuery] decimal? minPrice, [FromQuery] decimal? maxPrice)
        {
            var q = _products.AsEnumerable();
            if (!string.IsNullOrWhiteSpace(name))
            {
                q = q.Where(p => p.Name.Contains(name, StringComparison.OrdinalIgnoreCase));
            }
            if (minPrice.HasValue)
            {
                q = q.Where(p => p.Price >= minPrice.Value);
            }
            if (maxPrice.HasValue)
            {
                q = q.Where(p => p.Price <= maxPrice.Value);
            }
            return Ok(q);
        }

        /// <summary>
        /// Create a single product.
        /// </summary>
        /// <param name="product">Product to create.</param>
        /// <returns>The created product.</returns>
        [HttpPost]
        public ActionResult<Product> CreateOne([FromBody] Product product)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            product.Id = Guid.NewGuid();
            _products.Add(product);
            return CreatedAtAction(nameof(GetById), new { id = product.Id }, product);
        }

        /// <summary>
        /// Create multiple products.
        /// </summary>
        /// <param name="products">Products to create.</param>
        /// <returns>List of created products.</returns>
        [HttpPost("batch")]
        public ActionResult<IEnumerable<Product>> CreateMany([FromBody] IEnumerable<Product> products)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var created = new List<Product>();
            foreach (var p in products)
            {
                p.Id = Guid.NewGuid();
                _products.Add(p);
                created.Add(p);
            }
            return Created("", created);
        }

        /// <summary>
        /// Update a single product.
        /// </summary>
        /// <param name="id">Product id.</param>
        /// <param name="product">New product data.</param>
        /// <returns>NoContent on success; 404 if not found.</returns>
        [HttpPut("{id:guid}")]
        public ActionResult UpdateOne(Guid id, [FromBody] Product product)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var existing = _products.FirstOrDefault(p => p.Id == id);
            if (existing == null) return NotFound();

            existing.Name = product.Name;
            existing.Description = product.Description;
            existing.Price = product.Price;
            existing.Quantity = product.Quantity;

            return NoContent();
        }

        /// <summary>
        /// Update multiple products.
        /// </summary>
        /// <param name="products">Products with ids to update.</param>
        /// <returns>200 with list of updated ids.</returns>
        [HttpPut("batch")]
        public ActionResult<IEnumerable<Guid>> UpdateMany([FromBody] IEnumerable<Product> products)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            var updated = new List<Guid>();
            foreach (var p in products)
            {
                var existing = _products.FirstOrDefault(x => x.Id == p.Id);
                if (existing == null) continue;
                existing.Name = p.Name;
                existing.Description = p.Description;
                existing.Price = p.Price;
                existing.Quantity = p.Quantity;
                updated.Add(existing.Id);
            }
            return Ok(updated);
        }

        /// <summary>
        /// Delete a single product by id.
        /// </summary>
        /// <param name="id">Product id.</param>
        /// <returns>NoContent on success; 404 if not found.</returns>
        [HttpDelete("{id:guid}")]
        public ActionResult DeleteOne(Guid id)
        {
            var existing = _products.FirstOrDefault(p => p.Id == id);
            if (existing == null) return NotFound();
            _products.Remove(existing);
            return NoContent();
        }

        /// <summary>
        /// Delete multiple products by ids.
        /// </summary>
        /// <param name="ids">Array of ids to delete.</param>
        /// <returns>200 with deleted ids.</returns>
        [HttpPost("delete")]
        public ActionResult<IEnumerable<Guid>> DeleteMany([FromBody] IEnumerable<Guid> ids)
        {
            var deleted = new List<Guid>();
            foreach (var id in ids)
            {
                var existing = _products.FirstOrDefault(p => p.Id == id);
                if (existing == null) continue;
                _products.Remove(existing);
                deleted.Add(id);
            }
            return Ok(deleted);
        }
    }
}
