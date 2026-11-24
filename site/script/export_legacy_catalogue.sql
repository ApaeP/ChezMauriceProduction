-- Run with psql -XAt on a local restoration of the old database.
BEGIN READ ONLY;
SELECT json_build_object(
  'version', 1,
  'source', 'rails',
  'videos', COALESCE(json_agg(json_build_object(
    'id', v.id,
    'title', v.title,
    'description', v.description,
    'position', v.position,
    'vimeo_url', v.url,
    'categories', (
      SELECT COALESCE(json_agg(DISTINCT c.name ORDER BY c.name), '[]'::json)
      FROM categories c JOIN video_categories vc ON vc.category_id = c.id
      WHERE vc.video_id = v.id
    ),
    'thumbnail', (
      SELECT json_build_object('key', b.key, 'file', v.id::text, 'filename', b.filename,
                               'byte_size', b.byte_size, 'checksum', b.checksum)
      FROM active_storage_attachments a JOIN active_storage_blobs b ON b.id = a.blob_id
      WHERE a.record_type = 'Video' AND a.record_id = v.id AND a.name = 'photo'
    )
  ) ORDER BY v.position NULLS LAST, v.id), '[]'::json)
)
FROM videos v;
COMMIT;
