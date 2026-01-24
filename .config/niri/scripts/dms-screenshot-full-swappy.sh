#!/bin/bash
bash -ic "dms screenshot full --stdout | swappy -f - -o - | wl-copy"
