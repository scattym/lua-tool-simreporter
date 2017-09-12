import zlib


def deflate(filename, outfile=None):
    f = open(filename)
    data = f.read()
    f.close()

    compress = zlib.compressobj(
        0,                # level: 0-9
        zlib.DEFLATED,        # method: must be DEFLATED
        8,      # window size in bits:
                              #   -15..-8: negate, suppress header
                              #   8..15: normal
                              #   16..30: subtract 16, gzip header
        2,   # mem level: 1..8/9
        0                    # strategy:
                              #   0 = Z_DEFAULT_STRATEGY
                              #   1 = Z_FILTERED
                              #   2 = Z_HUFFMAN_ONLY
                              #   3 = Z_RLE
                              #   4 = Z_FIXED
    )
    deflated = compress.compress(data)
    deflated += compress.flush()

    if outfile is not None:
        f = open(outfile, 'w')
        f.write(deflated)
        f.close()

    return deflated


#deflate("/tmp/blah", "test.zip")
