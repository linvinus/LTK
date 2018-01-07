extern class FT_Face {}
extern class FT_Library {}

extern int FT_Init_FreeType(out FT_Library alibrary );
extern int FT_New_Face( FT_Library   library,
                        string       filepathname,
                        long         face_index,
                        out FT_Face  aface );

extern Cairo.FontFace cairo_ft_font_face_create_for_ft_face(FT_Face face, int load_flags);
extern void FT_Done_Face (FT_Face face);


public class FontLoader {
  static FT_Face face;

  public static Cairo.FontFace load(string path) throws Error {
    FT_Library library;
    FT_Init_FreeType(out library);
    var error = FT_New_Face(library, path, 0, out face);
    if (error != 0) throw new FileError.ACCES("Error: unable to open font '%s'",path);
    return cairo_ft_font_face_create_for_ft_face(face, 0);
  }
  public static void destroy(){
    FT_Done_Face(face);
  }

}

