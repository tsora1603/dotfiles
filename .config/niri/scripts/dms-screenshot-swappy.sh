#!/bin/bash
bash -ic "dms screenshot --stdout | swappy -f - -o - | wl-copy"
